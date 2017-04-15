defmodule Bitcoin.Protocol.Types.TxInput do

  alias Bitcoin.Protocol.Types.VarInteger
  alias Bitcoin.Protocol.Types.Outpoint

  defstruct previous_output: %Outpoint{}, # The previous output transaction reference, as an OutPoint structure
            signature_script: <<>>, # Computational Script for confirming transaction authorization
            sequence: 0 # Transaction version as defined by the sender. Intended for "replacement" of transactions when information is updated before inclusion into a block.

  @type t :: %__MODULE__{
    previous_output: Outpoint.t,
    signature_script: bitstring,
    sequence: non_neg_integer
  }

  defimpl Inspect, for: __MODULE__ do
    def inspect(data, _opts) do
      "%In{ ##{data.sequence} output: #{data.previous_output |> Kernel.inspect}, sig: #{data.signature_script |> Base.encode16} }"
    end
  end

  def parse_stream(data) do

    [outpoint, payload] = Outpoint.parse_stream(data)
    [signature_script_size, payload] = VarInteger.parse_stream(payload)
    << script :: bytes-size(signature_script_size), sequence :: unsigned-little-integer-size(32), payload :: binary >> = payload

    [%__MODULE__{
      previous_output: outpoint,
      signature_script: script,
      sequence: sequence
    }, payload]

  end

  def serialize(%__MODULE__{} = s) do
    (s.previous_output |> Outpoint.serialize) <>
    (s.signature_script |> byte_size |> VarInteger.serialize) <>
    s.signature_script <>
    << s.sequence ::  unsigned-little-integer-size(32) >>
  end

end
