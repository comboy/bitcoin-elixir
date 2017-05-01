defmodule Bitcoin.Tx.Sighash do

  @moduledoc """
  Transaction signature hash.

  Hash of the transaction data used for signing.
  """

  @sighash_all          0x01
  @sighash_none         0x02
  @sighash_single       0x03
  @sighash_anyonecanpay 0x80

  use Bitwise

  alias Bitcoin.Protocol.Types
  alias Bitcoin.Protocol.Messages

  @doc """
  Calculate transaction hash for signing

  documentation: https://en.bitcoin.it/wiki/OP_CHECKSIG#cite_note-1
  """
  @spec sighash(Messages.Tx.t, non_neg_integer, binary, byte) :: binary
  def sighash(%Messages.Tx{} = tx, input_number, sub_script, sighash_type \\ @sighash_all) do
    tx = tx |> Map.put(:inputs,
      # Set scripts for all transaction inputs to an empty script
      tx.inputs
        |> Enum.map(fn input -> input |> Map.put(:signature_script, <<>>) end)
        # Set script for current transaction input to sub_script
        |> List.replace_at(input_number, tx.inputs |> Enum.at(input_number) |> Map.put(:signature_script, sub_script |> remove_op_codeseparator))
    )
    case tx |> prepare_tx(input_number, sighash_type) do
      # Due to a bug in bitcoin core, in case of error (more inputs than outputs for @sighash_single
      # instead of failing, sighash returns hash like below
      # some more info  https://bitcointalk.org/index.php?topic=260595.0
      :error ->
        <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1>>
      tx ->
        # Append sighash as int32 to the serialized transaction
        buf = Messages.Tx.serialize(tx) <> << sighash_type :: little-integer-size(32) >>
        # Double sha256
        buf |> Bitcoin.Util.double_sha256
    end
  end

  @doc """
  Check if given sighash byte is valid (defined type).
  """
  @spec valid_type?(byte) :: boolean
  # TODO added @sighash_anyonecanpay as a valid value, but I'm not sure bitcoin core also accepts it,
  # looking at the code it doesn't seem to: https://github.com/bitcoin/bitcoin/blob/80c3a734298e824f9321c4efdd446086a3baad89/src/script/interpreter.cpp#L184
  def valid_type?(@sighash_anyonecanpay), do: true
  def valid_type?(type) do
    type = type &&& (~~~@sighash_anyonecanpay)
    type in [@sighash_all, @sighash_single, @sighash_none]
  end

  @spec prepare_tx(Messages.Tx.t, non_neg_integer, byte) :: Messages.Tx.t | :error
  defp prepare_tx(tx, input_number, sighash_type)

  # SIGHASH_NONE - sign none of the outputs
  defp prepare_tx(%Messages.Tx{} = tx, input_number, sighash_type) when (sighash_type &&& 0x1f) == @sighash_none do
    tx
    # Remove all outtputs
    |> Map.put(:outputs, [])
    # Set all inputs sequence number to 0
    |> zero_sequence_numbers(input_number)
    # Remove sighash none and call it again, we still may need to apply ANYONECANPAY
    |> prepare_tx(input_number, sighash_type ^^^ @sighash_none)
  end

  # SIGHASH_NONE - sign only one of the outputs
  defp prepare_tx(%Messages.Tx{} = tx, input_number, sighash_type) when (sighash_type &&& 0x1f) == @sighash_single do
    if input_number >= length(tx.outputs) do
      :error
    else
      # Resize outputs size to input_number + 1, and clear all outputs other than the one matching input_number
      matched_output = tx.outputs |> Enum.at(input_number)
      tx
      |> Map.put(:outputs,
        (0..(input_number))
        |> Enum.map(fn _output -> %Types.TxOutput{pk_script: <<>>, value: -1} end)
        |> List.replace_at(input_number, matched_output)
      )
      # Set all inputs sequence number to 0
      |> zero_sequence_numbers(input_number)
      # Remove sighash none and call it again, we still may need to apply ANYONECANPAY
      |> prepare_tx(input_number, sighash_type ^^^ @sighash_single)
    end
  end

  # SIGHASH_ANYONECANPAY - only sign the script transaction input
  defp prepare_tx(%Messages.Tx{} = tx, input_number, sighash_type) when (sighash_type &&& @sighash_anyonecanpay) == @sighash_anyonecanpay do
    tx
    |> Map.put(:inputs, [tx.inputs |> Enum.at(input_number)])
  end

  # SIGHASH_ALL - nothing to do
  defp prepare_tx(tx, _input_number, _sighash_type), do: tx

  @spec remove_op_codeseparator(binary) :: binary
  defp remove_op_codeseparator(script) do
    script
    |> Bitcoin.Script.parse
    |> Enum.filter(fn op -> op != :OP_CODESEPARATOR end)
    |> Bitcoin.Script.to_binary
  end

  @spec zero_sequence_numbers(Messages.Tx.t, non_neg_integer) :: Messages.Tx.t
  defp zero_sequence_numbers(%Messages.Tx{} = tx, input_number) do
    tx
    |> Map.put(:inputs,
      tx.inputs
      |> Enum.with_index
      # Current input sequence number is not being set to zero
      |> Enum.map(fn {input, idx} ->  idx == input_number && input ||  Map.put(input, :sequence, 0) end)
    )
  end

end
