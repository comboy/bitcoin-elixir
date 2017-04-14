defmodule Bitcoin.Block.Validation do
  alias Bitcoin.Protocol.Messages.Block

  def hash_below_target(%Block{} = block) do
    << hash_int :: unsigned-little-integer-size(256) >> = Bitcoin.Block.hash(block)
    target_int = block.bits |> Bitcoin.Block.CompactBits.decode
    if hash_int <= target_int, do: :ok, else: {:error, :hash_above_target}
  end

  def merkle_root(%Block{} = block) do
    if Bitcoin.Block.merkle_root(block) == block.merkle_root do
      :ok
    else
      {:error, :merkle_root_invalid}
    end
  end

  def has_parent(%Block{previous_block: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>} = block), do: :ok
  def has_parent(%Block{previous_block: previous_hash} = block) do
    case Bitcoin.Node.Storage.get_block(previous_hash) do #  FIXME no need to fetch it, just check it exists
      nil -> {:error, :no_parent}
      _   -> :ok
    end
  end

  def coinbase(%Block{transactions: []} = block), do: {:error, :no_coinbase_tx}
  def coinbase(%Block{} = block) do
    [tx | _] = block.transactions
    # TODO validate output value
    :ok
  end

  def transactions(%Block{} = block) do
    [coinbase | transactions] = block.transactions
    transactions
    |> Enum.reduce(:ok, fn (tx, result) -> 
      case result do
        :ok -> tx |> Bitcoin.Tx.validate(%{block: block})
        {:error, err}  -> {:error, err}
      end
    end)
  end
end
