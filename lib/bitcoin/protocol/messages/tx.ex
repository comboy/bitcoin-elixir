defmodule Bitcoin.Protocol.Messages.Tx do

  @moduledoc """
    tx describes a bitcoin transaction, in reply to getdata.

    https://en.bitcoin.it/wiki/Protocol_documentation#tx
  """

  alias Bitcoin.Protocol.Types.TxInput
  alias Bitcoin.Protocol.Types.TxOutput

  import Bitcoin.Protocol

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
    inputs: list(TxInput.t),
    outputs: list(TxOutput.t),
    lock_time: non_neg_integer
  }

  @spec parse_stream(binary) :: {t, binary}
  def parse_stream(data) do

    <<version :: little-integer-size(32), payload :: binary>> = data

    {inputs, payload} =  payload |> collect_items(TxInput)
    {outputs, payload} = payload |> collect_items(TxOutput)

    <<lock_time::unsigned-little-integer-size(32), remaining :: binary>> = payload

    struct = %__MODULE__{
      version: version,
      inputs: inputs,
      outputs: outputs,
      lock_time: lock_time
    }

    {struct, remaining}
  end

  @spec parse(binary) :: t
  def parse(data) do
    {struct, ""} = parse_stream(data)
    struct
  end

  @spec serialize(t) :: binary
  def serialize(%__MODULE__{} = s) do
    << s.version :: little-integer-size(32) >>
    <>
    ( s.inputs |> serialize_items )
    <>
    ( s.outputs |> serialize_items )
    <>
    << s.lock_time :: unsigned-little-integer-size(32) >>
  end

end
