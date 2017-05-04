defmodule Bitcoin.Node.Storage.Engine.Dummy do
  @moduledoc """
    In memory storage to use for tests and playing with in dev env.
  """

  use GenServer
  use Bitcoin.Common

  require Logger

  alias Bitcoin.Protocol.Messages

  # warning: this storage is really dumb, it will take some inodes (each block is a separate file)
  @persistence true
  @persistence_dir "tmp/blocks/#{@network}"

  # I don't like it here, I don't know how to avoid it without impacting performance
  if Mix.env == :test, do: @persistence false

  # TODO behavior
  # TODO storage model:
  # * tx hashes instead of transactionss
  # * height
  # * which chain (or maybe store that info somewhere else?)

  @default_timeout 60_000

  def start_link(opts \\ %{}), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def call(arg), do: GenServer.call(__MODULE__, arg, @default_timeout)

  def store_block(%Messages.Block{} = block), do: call {:store_block, block}
  def store_tx(%Messages.Tx{} = block), do: call {:store_tx, block}
  def get_block(hash), do: call {:get_block, hash}
  def get_tx(hash), do: call {:get_tx, hash}
  def max_height(), do: call :max_height
  def get_blocks_with_height(height), do: call {:get_blocks_with_height, height}

  def init(opts) do
    state = %{
      opts: opts,
      block: %{},
      max_height: nil,
      block_by_height: %{}, # we even have an index!
      tx: %{}
    }
    state = if @persistence do
      File.mkdir_p(@persistence_dir)
      state |> load_stored
    else
      state
    end
    {:ok, state}
  end

  def handle_call({:get_blocks_with_height, height}, _from, state) do
    blocks =
      state.block_by_height[height]
      |> Enum.map(fn hash -> state.block[hash] |> Map.put(:hash, hash) end)
    {:reply, blocks, state}
  end

  def handle_call({:store_block, %Messages.Block{} = block}, _from, state) do
    {:reply, :ok, state |> store_block(block)}
  end

  def handle_call({:store_tx, %Messages.Tx{} = tx}, _from, state) do
    {:reply, :ok, state |> store_tx(tx)}
  end

  def handle_call({:get_tx, hash}, _from, state) do
    {:reply, state.tx[hash], state}
  end

  def handle_call({:get_block, hash}, _from, state) do
    {:reply, state.block[hash], state}
  end

  def handle_call(:max_height, _from, state) do
    {:reply, state.max_height, state}
  end

  defp store_block(state, block, opts \\ []) do
    hash = block |> Bitcoin.Block.hash
    Logger.info "Storing block #{block.height} | #{hash |> Bitcoin.Util.hash_to_hex} #{opts[:loading] && "(loading stored)" || ""}"
    if !opts[:loading] && @persistence, do: File.write(block.height |> block_path, block |> Messages.Block.serialize)
    block.transactions
    |> Enum.reduce(state, fn(tx, state) -> state |> store_tx(tx)  end)
    |> put_in([:block, hash], block) # TODO block sholud only store tx hashes
    |> put_in([:block_by_height, block.height], [hash | (state.block_by_height[block.height] || [])])
    |> Map.put(:max_height, max(block.height, state.max_height) || block.height)
  end

  defp load_stored(state), do: load_stored(state, 0)

  defp load_stored(state, height) do
    case height |> block_path |> File.read do
      {:ok, block_data} ->
        block = Messages.Block.parse(block_data) |> Map.put(:height, height)
        state
        |> store_block(block, loading: true)
        |> load_stored(height + 1)
      {:error, _} -> state
    end
  end

  defp store_tx(state, tx) do
    hash = tx |> Bitcoin.Tx.hash
    state |> put_in([:tx, hash], tx)
  end

  def block_path(height) do
    Path.join(@persistence_dir, "block_#{height}.dat")
  end

end
