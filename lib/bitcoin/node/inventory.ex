defmodule Bitcoin.Node.Inventory do

  @moduledoc """
    Inventory module is responsible for fetching missing data from peers, and broadcasting it forward
    after validation. Fetched data should be added to storage / mempool.
  """

  use GenServer

  require Lager

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types
  alias Bitcoin.Node.Storage
  alias Bitcoin.Node

  @get_data_timeout 60_000
  @sync_check_time  20_000

  def start_link(opts \\ %{}), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # Report inventory spotted from connected peer. This is called by the peer module when it receives INV
  def seen(inv_vector)
  def seen(%Types.InventoryVector{reference_type: :msg_tx, hash: hash}), do: seen({:tx, hash})
  def seen(%Types.InventoryVector{reference_type: :msg_block, hash: hash}), do: seen({:block, hash})
  def seen({item_type, hash}), do: GenServer.call(__MODULE__, {:seen, {item_type, hash}})

  # Add data to inventory. Called by Peer on BLOCK and TX
  def add(%Messages.Block{} = block), do: GenServer.call(__MODULE__, {:add, {:block, block}})

  def init(%{modules: modules}) do
    state = %{
      modules: modules,
      items: %{}
    }
    self() |> send(:periodical_sync)
    # TODO periodical items cleanup (by time), otherwise it will just keep growing
    {:ok, state}
  end

  # Periodicaly check if we are still synchronizing
  def handle_info(:periodical_sync, state) do
    self() |> send(:sync)
    self() |> Process.send_after(:periodical_sync, @sync_check_time)
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
      peer = state.modules[:connection_manager].peers |> List.first
      # TODO upgrade to get headers later
      peer && get_blocks(peer)
    else
      # retry after 1s if we are disconnected
      self() |> Process.send_after(:sync, 1000)
    end
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


  def handle_call({:add, {:block, block}}, _From, state) do
    hash = block |> Bitcoin.Block.hash
    key = {:block, hash}

    # TODO we probably want some kind of queue, Storage may take its sweet time so this should be async
    # TODO case when key is not on the list anymore (unlikely, but could probably happen due to cleanup)

    state = case Storage.store_block(block) do
      :ok -> 
        state |> put_in([:items, key, :status], :present)# TODO update list
      {:error, error} ->
        Lager.error "Failed to store block #{hash} #{error |> inspect}"
        state |> put_in([:items, key, :status], :invalid)# TODO update list
    end

    # If we added all blocks let's check if there aren't any more to fetch
    state |> check_sync

    {:reply, :ok, state}
  end

  # TODO the way we handle it currently, e.g. when we get response to getblocks, we are going to do getData
  # for each block separately, that's no good, nee to batch it
  def handle_call({:seen, {item_type, hash} = key}, {pid, _tag}, state) do
    case state.items[key] do

      # It's the first time we hear about the item
      nil ->
        if item_type == :block && Storage.get_block(hash) do # FIXME no get_block just check it exists
          state = state |> put_in([:items, key], %{status: :present, time: Bitcoin.Node.timestamp()})
          {:reply, {:ok, :present}, state}
        else
          # TODO for tx we will want to check if it's in utxo / mempool
          state = state |> put_in([:items, key],
            %{
              status: :waiting,
              # Seen from is actually seen_from - requested_from, in a single field
              # that's why it starts empty, we are already sending request to this pid
              seen_from: [],
              time: Bitcoin.Node.timestamp()
            }
          )
          pid |> request_item(key)
          {:reply, {:ok, :new}, state}
        end

      # We've already heard about it, but haven't finished fetching it yet
      %{status: :waiting} = info ->
        state = state |> put_in([:items, key],
          info |> Map.put(:seen_from, [pid | info.seen_from])
        )
        {:reply, {:ok, :wating}, state}

      # The item is already fetched
      _item -> {:reply, {:ok, :present}, state}
    end
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

  # TODO maybe block locator hashes belong to some blockchain module which also takes care
  # of decidnig which is the main chain?

  # Block locator hashes: newest back to genesis block (dense to start, but then sparse)
  # We take first block then 2 blocks behind it, then 4 blocks behind it and so on until genesis
  # (and we include genesis block hash)
  def block_locator_hashes, do: [ Storage.get_blocks_with_height(Storage.max_height()) |> List.first |> Bitcoin.Block.hash, Bitcoin.Const.genesis_hash()]

  # FIXME seemingly proper implementation below doesn't seem to work, maybe just switch to get headers directly to save time
  # The implementation above of course sucks heavily and will fail on the first encountered fork

  #def block_locator_hashes, do: block_locator_hashes([Bitcoin.Const.genesis_hash()], Storage.max_height, 1)
  #def block_locator_hashes(hashes, height, multiplier) when height < 1, do: hashes
  #def block_locator_hashes(hashes, height, multiplier) do
    #hash = Storage.get_blocks_with_height(height) |> List.first |> Bitcoin.Block.hash
    #block_locator_hashes([hash | hashes], height - multiplier, multiplier)
  #end

  # Request blocks from the peer
  def get_blocks(peer) do
    msg = %Messages.GetBlocks{
      version: Node.protocol_version(),
      block_locator_hashes: block_locator_hashes()
    }
    peer |> send({:send_message, msg})
  end

  defp item_to_inv_vector({:tx, hash}),    do: %Types.InventoryVector{reference_type: :msg_tx, hash: hash}
  defp item_to_inv_vector({:block, hash}), do: %Types.InventoryVector{reference_type: :msg_block, hash: hash}

end
