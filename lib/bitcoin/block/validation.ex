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
end
