defmodule Bitcoin.Tx do
  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types

  @sighash_all          0x01
  @sighash_none         0x02
  @sighash_single       0x03
  @sighash_anyonecanpay 0x80

  # TODO Uhm. Besides the four listed hashtypes only a hashtype of value 0 appears a few times in the (main) block chain (and is handled like SIGHASH_ALL). 

  def hash(%Messages.Tx{} = tx) do
    tx
      |> Messages.Tx.serialize
      |> Bitcoin.Util.double_sha256
  end

  # TODO other sighash types
  def sighash(tx, input_number, sub_script, sighash_type \\ @sighash_all) do
    tx = tx |> Map.put(:inputs,
      # Set scripts for all transaction inputs to an empty script (single zero byte)
      tx.inputs |> Enum.map(fn input -> input |> Map.put(:signature_script, <<0>>) end)
      # Set script for current transaction input to sub_script
      |> List.replace_at(input_number, Enum.at(tx.inputs, input_number) |> Map.put(:signature_script, sub_script))
    )
    # Append sighash as int32 to the serialized transaction
    buf = Messages.Tx.serialize(tx) <> << sighash_type :: unsigned-little-integer-size(32) >>
    # Hash only once because the second hash is done by :crypto.verify
    :crypto.hash(:sha256, buf)
  end

  def verify(hash, sig, pk) do
    :crypto.verify(:ecdsa, :sha256, hash, sig, [pk, :secp256k1])
  end

  # TODO
  def validate(%Messages.Tx{} = tx), do: :ok
end
