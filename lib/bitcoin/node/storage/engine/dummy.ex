defmodule Bitcoin.Node.Storage.Engine.Dummy do
  @moduledoc """
    In memory storage to use for tests and playing with in dev env.
  """
  use GenServer

  require Lager

  alias Bitcoin.Node.Storage
  alias Bitcoin.Protocol.Messages

  # TODO behavior
  # TODO storage model:
  # * tx hashes instead of transactionss
  # * height
  # * which chain (or maybe store that info somewhere else?)

  def start_link(opts \\ %{}), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def store_block(%Messages.Block{} = block), do: GenServer.call(__MODULE__, {:store_block, block})
  def store_tx(%Messages.Tx{} = block), do: GenServer.call(__MODULE__, {:store_tx, block})
  def get_block(hash), do: GenServer.call(__MODULE__, {:get_block, hash})
  def get_tx(hash), do: GenServer.call(__MODULE__, {:get_tx, hash})
  def max_height(), do: GenServer.call(__MODULE__, :max_height)
  def get_blocks_with_height(height), do: GenServer.call(__MODULE__, {:get_blocks_with_height, height})

  def init(opts) do
    state = %{
      opts: opts,
      block: %{},
      tx: %{}
    }
    {:ok, state}
  end

  def handle_call({:get_blocks_with_height, height}, _from, state) do
    blocks =
      state.block
      |> Enum.filter(fn {_hash, b} -> b.height == height end)
      |> Enum.map(fn {hash, b} -> b |> Map.put(:hash, hash) end)
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
    max_height =
      state.block
      |> Enum.map(fn {hash, block} -> block.height end)
      |> Enum.max(fn -> nil end)
    {:reply, max_height, state}
  end

  defp store_block(state, block) do
    hash = block |> Bitcoin.Block.hash
    Lager.info "Storing block #{block.height} | #{hash |> Bitcoin.Util.friendly_hash}"
    #File.write("tmp/block_#{block.height}.dat", block |> Messages.Block.serialize)
    block.transactions
    |> Enum.reduce(state, fn(tx, state) -> state |> store_tx(tx)  end)
    |> put_in([:block, hash], block) # TODO block sholud only store tx hashes
  end

  defp store_tx(state, tx) do
    hash = tx |> Bitcoin.Tx.hash
    state |> put_in([:tx, hash], tx)
  end

end
