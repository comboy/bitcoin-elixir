defmodule Bitcoin.Block do

  use Bitcoin.Common

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Block.Validation

  @type t_hash :: Bitcoin.t_hash

  @doc """
  Compute hash of the provided block, which is double sha256 of the serialized block header.
  """
  @spec hash(Messages.Block.t) :: t_hash
  def hash(%Messages.Block{} = block) do
    block
      |> Messages.Block.serialize_header()
      |> Bitcoin.Util.double_sha256
  end

  @doc """
  Compute the root hash of the transactions merkle tree for the provided block.
  """
  @spec merkle_root(Messages.Block.t) :: Bitcoin.t_hash
  def merkle_root(%Messages.Block{} = block) do
    block.transactions
      |> Enum.map(&Bitcoin.Tx.hash/1)
      |> Bitcoin.Util.merkle_tree_hash
  end

  @doc """
  Returns sum of all transaction fees in the provided block message
  """
  @spec total_fees(Messages.Block.t) :: number
  def total_fees(%Messages.Block{} = block) do
    [_coinbase | transactions ] = block.transactions
    transactions |> Enum.reduce(0, fn (tx, acc) ->
      acc + Bitcoin.Tx.fee(tx, %{block: block})
    end)
  end

  @doc """
  Validate corectness of the block. Function checks if:

  * parent block exists
  * merkle root hash matches with the calculated one
  * block hash below target
  * TODO target matches difficulty algorithm
  * has coinbase transaction
  * block reward is correct
  """
  @spec validate(Message.Block.t) :: :ok | {:error, term}
  def validate(block)

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

end
