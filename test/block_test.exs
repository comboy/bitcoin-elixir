defmodule Bitcoin.BlockTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages

  test "merkle root 100_000" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)
    assert block.merkle_root == block |> Bitcoin.Block.merkle_root
  end

  test "merkle root 460_281" do
    {:ok, payload} = File.read("test/data/blk_460281.dat")
    block = Messages.Block.parse(payload)
    assert block.merkle_root == block |> Bitcoin.Block.merkle_root
  end

  test "hash 100_000" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)
    hash = block |> Bitcoin.Block.hash() |> Bitcoin.Util.friendly_hash
    assert hash == "000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506"
  end

  test "hash 460_281" do
    {:ok, payload} = File.read("test/data/blk_460281.dat")
    block = Messages.Block.parse(payload)
    hash = block |> Bitcoin.Block.hash() |> Bitcoin.Util.friendly_hash
    assert hash == "0000000000000000003392c77dc421b76daefe86cb85f265266a619919dd383c"
  end

end

