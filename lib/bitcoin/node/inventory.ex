defmodule Bitcoin.Node.Inventory do

  @moduledoc """
    Inventory module is responsible for fetching missing data from peers, and broadcasting it forward
    after validation. Fetched data should be added to storage / mempool.
  """

  use Bitcoin.Common
  use GenServer

  require Logger

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types
  alias Bitcoin.Node.Storage
  alias Bitcoin.Node

  @get_data_timeout  60_000
  @sync_check_time   20_000
  @cleanup_frequency 60_000

  @items_limit 10_000

  # State structure :: %{
  #   items: %{ {item_type, hash} => item)
  # }
  #
  # item :: %{
  #   status: :waiting | :present | :timeout | :orphan | :invalid
  #   time: int # timestamp of the first time item was seen
  #   seen_from: list(pid) # List of Peer pids which have reported that the have the item
  #   item: %Massages.Block{} | %Messages.Tx{}
  # }
  #
  # items status:
  # * waiting - some peer reported INV and we sent GetData to retrieve the item
  #             in case we don't receive it, we try the next peer from the :seen_from list
  # * timeout - we went through all seen_from list and still haven't got the item
  # * present - item received and validated
  # * invalid - received the item but the validation failed
  # * orphan  - validation failed because the item depends on another item which we don't yet have


  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # Report inventory spotted from connected peer. This is called by the peer module when it receives INV
  def seen(inv_vector)
  def seen(%Types.InventoryVector{reference_type: :msg_tx, hash: hash}), do: seen({:tx, hash})
  def seen(%Types.InventoryVector{reference_type: :msg_block, hash: hash}), do: seen({:block, hash})
  def seen({item_type, hash}), do: GenServer.cast(__MODULE__, {:seen, {item_type, hash}, self()})

  # Add data to inventory. Called by Peer on BLOCK and TX
  def add(%Messages.Block{} = block), do: GenServer.cast(__MODULE__, {:add, {:block, block}})

  def init(_) do
    state = %{
      items: %{}
    }
    self() |> send(:periodical_sync)
    self() |> send(:periodical_cleanup)
    {:ok, state}
  end

  # Periodically check if we are still synchronizing
  def handle_info(:periodical_sync, state) do
    self() |> send(:sync)
    self() |> Process.send_after(:periodical_sync, @sync_check_time)
    {:noreply, state}
  end

  # Periodically cleanup the list of items
  def handle_info(:periodical_cleanup, state) do
    self() |> send(:cleanup)
    self() |> Process.send_after(:periodical_cleanup, @cleanup_frequency)
    {:noreply, state}
  end

  # Synchronize node. It's responsible for fetching missing blockchain when we are behind.
  # TODO check if we are already synchronized (some heuristic? HEAD.time within last hour?
  # TODO make sure it's not called to often i.e. avoid spamming some peer with getblocks/getheaders
  def handle_info(:sync, state) do
    if Node.Network.connected? do
      # TODO this peer should be selected in a smarter way
      # Take into account height from the handshake and maybe latency
      # If we are super bored we could also try measure connection speed
      peer = @modules[:connection_manager].peers |> Enum.random
      # TODO upgrade to get headers later
      peer && get_blocks(peer)
    else
      # retry after 1s if we are disconnected
      self() |> Process.send_after(:sync, 1000)
    end
    {:noreply, state}
  end

  def handle_info(:cleanup, state) do
    state |> Map.put(:items,
      state.items |> Enum.sort_by(fn {_k, i} -> i[:time] end) |> Enum.reverse |> Enum.take(@items_limit) |> Enum.into(%{})
    )
    {:noreply, state}
  end

  # After we request some data from peer we queue this check in @get_data_timeout
  # to check if we got it, and request it from somebody else if it's not received
  # It may turn out to be lighter to just do it on the whole items list periodically
  def handle_info({:check_received, {_item_type, _hash} = key}, state) do
    info = state.items[key]
    cond do

      # We haven't got it, but some other peer has it, request it
      info[:status] == :waiting && length(info[:seen_from]) > 0 ->
        [pid | seen_from] = info[:seen_from]
        pid |> request_item(key)
        {:noreply, state |> put_in([:items, key, :seen_from], seen_from)}

      # We haven't got it, and we did not receive INV about it from anybody else,
      info[:status] == :waiting ->
        # I dunno what we do now, perhaps leave it as that and have a periodical cleanup
        {:noreply, state |> put_in([:items, key, :status], :timeout)}

      # Everything ok it was received
      true ->
        {:noreply, state}

    end
  end


  def handle_cast({:add, {:block, block}}, state) do
    hash = block |> Bitcoin.Block.hash
    key = {:block, hash}

    # TODO we probably want some kind of queue, Storage may take its sweet time so this should be async
    # TODO case when key is not on the list anymore (unlikely, but could probably happen due to cleanup)

    state = case Storage.store_block(block) do
      :ok ->
        state |> put_in([:items, key, :status], :present)
      {:error, :no_parent} ->
        Logger.warn "No parent for block #{hash |> Bitcoin.Util.hash_to_hex}"
        state
        |> put_in([:items, key, :status], :orphan)
        |> put_in([:items, key, :item], block)
        |> check_orphans
      {:error, error} ->
        Logger.error "Failed to store block #{hash |> Bitcoin.Util.hash_to_hex} #{error |> inspect}"
        state |> put_in([:items, key, :status], :invalid)
    end

    # If we added all blocks let's check if there aren't any more to fetch
    state |> check_sync

    {:noreply, state}
  end

  # TODO the way we handle it currently, e.g. when we get response to getblocks, we are going to do getData
  # for each block separately, that's no good, nee to batch it
  def handle_cast({:seen, {item_type, hash} = key, pid}, state) do
    state = case state.items[key] do

      # It's the first time we hear about the item
      nil ->
        if item_type == :block && Storage.has_block?(hash) do
          state |> put_in([:items, key], %{status: :present, time: Bitcoin.Node.timestamp()})
        else
          # TODO for tx we will want to check if it's in utxo / mempool
          pid |> request_item(key)
          state |> put_in([:items, key],
            %{
              status: :waiting,
              # Seen from is actually seen_from - requested_from, in a single field
              # that's why it starts empty, we are already sending request to this pid
              seen_from: [],
              time: Bitcoin.Node.timestamp()
            }
          )
        end

      # We've already heard about it, but haven't finished fetching it yet
      %{status: :waiting} = info ->
        state |> put_in([:items, key],
          info |> Map.put(:seen_from, [pid | info.seen_from])
        )

      # The item is already fetched
      _item -> state
    end
    {:noreply, state}
  end

  # Request item from the peer
  def request_item(pid, {_item_type, _hash} = item) do
    msg = %Bitcoin.Protocol.Messages.GetData{
      inventory_vectors: [item |> item_to_inv_vector]
    }
    pid |> send({:send_message, msg})
    # after some time, check if we got the item
    self() |> Process.send_after({:check_received, item}, @get_data_timeout)
    :ok
  end

  # Check if we are still waiting to receive some blocks. If not, let's sync some more.
  def check_sync(state) do
    waiting_count = state.items |> Enum.filter(fn {{item_type, _hash}, item} -> item_type == :block && item[:status] == :waiting end) |> Enum.count
    if waiting_count < 1, do: self() |> send(:sync)
    :ok
  end

  # Check if some if we already have parents for stored orphans
  def check_orphans(state) do
    state
    |> Map.put(:items, state.items |> Enum.map(fn {{item_type, hash} = key, item} ->
      item = cond do
        item_type == :block && item.status == :orphan ->
          case Storage.store_block(item[:item]) do
            :ok ->
             item |> Map.put(:status, :present)
            {:error, :no_parent} ->
              item
            {:error, error} ->
              Logger.error "Failed to store block #{hash |> Bitcoin.Util.hash_to_hex} #{error |> inspect}"
              item |> Map.put(:status, :invalid)
          end
        true -> item
      end
      {key, item}
    end) |> Enum.into(%{}))
  end

  def block_locator_hashes, do: block_locator_hashes([], Storage.max_height, 1, 1)
  def block_locator_hashes(hashes, height, _multiplier, _count) when height < 1, do: [@genesis_hash | hashes] |> Enum.reverse
  # Fierst add 10 hashes of the latest blocks
  def block_locator_hashes(hashes, height, multiplier, count) when count <= 10, do:
    block_locator_hashes([hash_for_height(height) | hashes], height - 1, multiplier, count + 1)
  # Then step backwards increases with each iteration
  def block_locator_hashes(hashes, height, multiplier, count), do:
    block_locator_hashes([hash_for_height(height) | hashes], height - multiplier, multiplier * 2, count + 1)

  # TODO we shouldn't need to fetch full block from storage to get that hash
  # TODO it shouldn't be just first block with given height, it should be the main chain
  defp hash_for_height(height), do: Storage.get_blocks_with_height(height) |> List.first |> Bitcoin.Block.hash

  # Request blocks from the peer
  defp get_blocks(peer) do
    Logger.info "Requesting blocks from #{peer |> inspect}"
    msg = %Messages.GetBlocks{
      version: Node.protocol_version(),
      block_locator_hashes: block_locator_hashes()
    }
    peer |> send({:send_message, msg})
  end

  defp item_to_inv_vector({:tx, hash}),    do: %Types.InventoryVector{reference_type: :msg_tx, hash: hash}
  defp item_to_inv_vector({:block, hash}), do: %Types.InventoryVector{reference_type: :msg_block, hash: hash}

end
