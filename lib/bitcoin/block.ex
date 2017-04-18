defmodule Bitcoin.Block do

  use Bitcoin.Common

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Block.Validation

  def hash(%Messages.Block{} = block) do
    block
      |> Messages.Block.serialize_header()
      |> Bitcoin.Util.double_sha256
  end

  def merkle_root(%Messages.Block{} = block) do
    block.transactions
      |> Enum.map(&Bitcoin.Tx.hash/1)
      |> merkle_tree_hash
  end

  def total_fees(%Messages.Block{} = block) do
    [_coinbase | transactions ] = block.transactions
    transactions |> Enum.reduce(0, fn (tx, acc) ->
      acc + Bitcoin.Tx.fee(tx, %{block: block})
    end)
  end

  def validate(@genesis_block), do: :ok
  def validate(%Messages.Block{} = block) do
    [
      &Validation.has_parent/1,
      &Validation.merkle_root/1,
      &Validation.hash_below_target/1,
      &Validation.transactions/1,
      &Validation.coinbase_value/1,
    ] |> Bitcoin.Util.run_validations(block)
  end



  def merkle_tree_hash([hash]), do: hash
  def merkle_tree_hash(list) when rem(length(list), 2) == 1, do: (list ++ [List.last(list)]) |> merkle_tree_hash
  def merkle_tree_hash(list) do
    list
      |> Enum.chunk(2)
      |> Enum.map(fn [a, b] -> Bitcoin.Util.double_sha256(a <> b) end)
      |> merkle_tree_hash
  end
end
