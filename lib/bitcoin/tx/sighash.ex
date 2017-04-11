defmodule Bitcoin.Tx.Sighash do

  use Bitwise

  alias Bitcoin.Protocol.Types
  alias Bitcoin.Protocol.Messages

  # TODO Uhm. Besides the four listed hashtypes only a hashtype of value 0 appears a few times in the (main) block chain (and is handled like SIGHASH_ALL).
  # documentation: https://en.bitcoin.it/wiki/OP_CHECKSIG#cite_note-1
  def sighash(tx, input_number, sub_script, sighash_type \\ @sighash_all) do
    #IO.puts "SIGHASH TYPE: #{sighash_type |> IO.inspect}"
    tx = tx |> Map.put(:inputs,
      # Set scripts for all transaction inputs to an empty script (single zero byte)
      tx.inputs |> Enum.map(fn input -> input |> Map.put(:signature_script, <<>>) end)
      # Set script for current transaction input to sub_script
      |> List.replace_at(input_number, Enum.at(tx.inputs, input_number) |> Map.put(:signature_script, sub_script))
    )
    # TODO anyonecanpay can be called after some other type, we onyl call the first match
    case tx |> sighash_preparation(input_number, sighash_type) do
      # Due to a bug in bitcoin core, in case of error (more inputs than outputs for @sighash_single
      # instead of failing, sighash returns hash like below
      # some more info  https://bitcointalk.org/index.php?topic=260595.0
      :error ->
        <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1>>
      tx ->
        # Append sighash as int32 to the serialized transaction
        buf = Messages.Tx.serialize(tx) <> << sighash_type :: unsigned-little-integer-size(32) >>
        # Hash only once because the second hash is done by :crypto.verify
        :crypto.hash(:sha256, buf)
    end
  end

  # SIGHASH_NONE - sign none of the outputs
  def sighash_preparation(tx, input_number, sighash_type) when sighash_type &&& 0x1f === @sighash_none do
    tx
    # Remove all outtputs
    |> Map.put(:outputs, [])
    # Set all inputs sequence number to 0
    |> Map.put(:inputs, tx.inputs |> Enum.map(fn input -> input |> Map.put(:sequence, 0) end))
  end

  # SIGHASH_NONE - sign only one of the outputs
  def sighash_preparation(tx, input_number, sighash_type) when sighash_type &&& 0x1f === @sighash_single do
    if input_number >= length(tx.outputs) do
      :error
    else
      # Resize outputs size to input_number + 1, and clear all outputs other than the one matching input_number
      matched_output = tx.outputs[input_number]
      tx = tx |> Map.put(:outputs, (0..(input_number+1)) |> Enum.map(fn output -> %Types.TransactionOutput{} end))
      tx
      |> Map.put(:outputs, tx.outputs |> List.replace_at(input_number, matched_output))
      # Set all inputs sequence number to 0
      |> Map.put(:inputs, tx.inputs |> Enum.map(fn input -> input |> Map.put(:sequence, 0) end))
    end
  end

  # SIGHASH_ANYONECANPAY - only sign the script transaction input
  def sighash_preparation(tx, input_number, sighash_type) when sighash_type &&& @sighash_anyonecanpay == @sighash_anyonecanpay do
    tx
    |> Map.put(:inputs, [tx.inputs |> Enum.at(input_number)])
  end

  # SIGHASH_ALL - nothing to do
  def sighash_preparation(tx, input_number, sighash_type), do: tx

end
