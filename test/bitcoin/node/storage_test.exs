defmodule Bitcoin.Node.StorageTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Node.Storage
  alias Bitcoin.Util

  test "store first bitcoin blocks" do
    {:ok, pid} = Storage.start_link
    blocks =
      File.read!("test/data/first_200_main_blocks.json")
      |> Poison.decode!
      |> Enum.map(&Base.decode16!/1)
      |> Enum.map(&Messages.Block.parse/1)

    b1 = blocks |> Enum.at(0)
    b2 = blocks |> Enum.at(1)
    b3 = blocks |> Enum.at(2)

    tx1 = b1.transactions |> Enum.at(0)
    tx1_hash = tx1 |> Bitcoin.Tx.hash

    assert Storage.max_height() == 0
    :ok = b1 |> Storage.store

    assert Storage.max_height() == 1
    {:error, :no_parent} = b3 |> Storage.store

    :ok = b2 |> Storage.store
    assert Storage.max_height() == 2

    :ok = b3 |> Storage.store

    assert Storage.max_height() == 3
    assert Storage.get_block(b2 |> Bitcoin.Block.hash) |> Map.delete(:height) == b2
    assert Storage.get_tx(tx1_hash) == tx1

    Process.exit(pid, :kill)
  end

  # When you enable Dummy storage persistance, this will try to store all blocks that are saved
  # in the tmp directory. Handy to rerun validations or to do a lame performance check
  # without fetching them each time. To run the test you can use this command:
  #
  #     mix test --include dummy_data
  #
  @tag dummy_data: true, timeout: 60_000*60*24
  test "store bitcoin blocks" do
    {:ok, pid} = Storage.start_link
    t = fn -> Util.militime end

    t0 = t.()
    start_validation_at = 1 # block number

    store_block = fn (num, fun) ->
      path = Storage.Engine.Dummy.block_path(num)
      if File.exists?(path) do
        block = File.read!(path) |> Messages.Block.parse
        t1 = t.()

        assert Storage.store(block, validate: num > start_validation_at) == :ok

        dt = t.() - t1
        tt = t.() - t0
        IO.puts("#{num} .#{block.transactions |> length} \t dt = #{round(dt*100) / 100}s \t T = #{round(tt)}s")

        fun.(num+1, fun)
      else
        :ok
      end
    end

    store_block.(1, store_block)
    Process.exit(pid, :kill)
  end

end
