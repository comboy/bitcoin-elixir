defmodule Bitcoin.TxTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages

  # Hash gets more thoroughly tested in other places e.g. Block.merkle_root()
  test "hash" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)

    tx = block.transactions |> List.first
    hash = tx |> Bitcoin.Tx.hash |> Bitcoin.Util.friendly_hash

    assert hash == "8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87"
  end
end
