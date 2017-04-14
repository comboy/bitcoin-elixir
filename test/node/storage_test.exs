defmodule Bitcoin.Node.StorageTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Node.Storage

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

  # There's a commented line in the Dummy storage that saves all blocks to the tmp directory
  # Thanks to that it's easy to do a rerun of the validations and storage on the blockchain
  # without fetching it each time. It can also be used to do some perf tests later.
  #@tag timeout: 60_000*60*24
  #test "store bitcoin blocks" do
    #{:ok, pid} = Storage.start_link
    #(1..124_200) |> Enum.map(fn num ->
      #block = File.read!("tmp/block_#{num}.dat") |> Messages.Block.parse
      #assert Storage.store(block) == :ok
      #if (block.transactions |> length) > 1 do
        #IO.puts "TX count: #{block.transactions |> length}"
      #end
      ##IO.puts Storage.max_height
    #end)
    #Process.exit(pid, :kill)
  #end

end
