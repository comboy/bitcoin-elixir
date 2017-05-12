defmodule Bitcoin.Node.Storage.Engine.PostgesTest do

  use ExUnit.Case

  alias Bitcoin.Node.Storage.Engine.Postgres
  alias Bitcoin.Protocol.Messages

  @moduletag :postgres

  setup do
    # Explicitly get a connection before each test
    {:ok, pid} = Postgres.start_link(%{})
    Ecto.Adapters.SQL.Sandbox.mode(Postgres.Repo, :manual)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postgres.Repo)
  end

  test "store a block" do
    assert Postgres.max_height() == nil

    block = File.read!("test/data/blk_100000.dat") |> Messages.Block.parse
    block_hash = Bitcoin.Block.hash(block)
    #{:ok, pid} = Postgres.start_link(%{})
    :ok = Postgres.store_block(block, %{height: 100_000}) |> IO.inspect
    tx1 = block.transactions |> Enum.at(1)

    assert Postgres.get_tx(tx1 |> Bitcoin.Tx.hash) == tx1

    assert Postgres.get_block(block_hash) == block

    assert Postgres.get_block_height(block_hash) == 100_000

    assert Postgres.max_height() == 100_000
  end
end
