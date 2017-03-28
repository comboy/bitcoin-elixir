defmodule Bitcoin.Protocol.Messages.Tx do

  @moduledoc """
    tx describes a bitcoin transaction, in reply to getdata.

    https://en.bitcoin.it/wiki/Protocol_documentation#tx
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.TransactionInput
  alias Bitcoin.Protocol.Types.TransactionOutput

  defstruct version: 0, # Transaction data format version
            inputs: [], # A list of 1 or more transaction inputs or sources for coins
            outputs: [], # A list of 1 or more transaction outputs or destinations for coins
            lock_time: 0 # The block number or timestamp at which this transaction is locked:
                         #   0 - Not Locked
                         #   < 500000000 - Block number at which this transaction is locked
                         #   >= 500000000 - UNIX timestamp at which this transaction is locked
                         # If all TxIn inputs have final (0xffffffff) sequence numbers then lock_time is irrelevant.
                         # Otherwise, the transaction may not be added to a block until after lock_time (see NLockTime).

  @type t :: %__MODULE__{
    version: integer, # note, this is signed
    inputs: [],
    outputs: [],
    lock_time: non_neg_integer
  }

  def parse_stream(data) do

    <<version :: little-integer-size(32), payload :: binary>> = data

    [tx_in_count, payload] = Integer.parse_stream(payload)

    [transaction_inputs, payload] = Enum.reduce(1..tx_in_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = TransactionInput.parse_stream(payload)
      [collection ++ [element], payload]
    end)

    [tx_out_count, payload] = Integer.parse_stream(payload)

    [transaction_outputs, payload] = Enum.reduce(1..tx_out_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = TransactionOutput.parse_stream(payload)
      [collection ++ [element], payload]
    end)

    <<lock_time::unsigned-little-integer-size(32), remaining :: binary>> = payload

    struct = %__MODULE__{
      version: version,
      inputs: transaction_inputs,
      outputs: transaction_outputs,
      lock_time: lock_time
    }

    [struct, remaining]

  end

  def parse(data) do
    [struct, ""] = parse_stream(data)
    struct
  end

  def serialize(%__MODULE__{} = s) do
    <<
      s.version :: little-integer-size(32),
    >> <>
      Integer.serialize(s.inputs |> Enum.count)
    <> (
      s.inputs
        |> Enum.map(&TransactionInput.serialize/1)
        |> Enum.reduce(<<>>, &(&2 <> &1))
    ) <>
      Integer.serialize(s.outputs |> Enum.count)
    <> (
      s.outputs
        |> Enum.map(&TransactionOutput.serialize/1)
        |> Enum.reduce(<<>>, &(&2 <> &1))
    ) <>
    << s.lock_time :: unsigned-little-integer-size(32) >>
  end

end
