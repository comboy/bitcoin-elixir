defmodule Bitcoin.Protocol.Types.TransactionInput do

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.Outpoint

  defstruct previous_output: %Outpoint{}, # The previous output transaction reference, as an OutPoint structure
            signature_script: <<>>, # Computational Script for confirming transaction authorization
            sequence: 0 # Transaction version as defined by the sender. Intended for "replacement" of transactions when information is updated before inclusion into a block.

  @type t :: %Bitcoin.Protocol.Types.TransactionInput{
    previous_output: Outpoint.t,
    signature_script: bitstring,
    sequence: non_neg_integer
  }

  def parse_stream(data) do

    [outpoint, payload] = Outpoint.parse_stream(data)
    [signature_script_size, payload] = Integer.parse_stream(payload)
    << script :: bytes-size(signature_script_size), sequence :: unsigned-little-integer-size(32), payload :: binary >> = payload

    [%Bitcoin.Protocol.Types.TransactionInput{
      previous_output: outpoint,
      signature_script: script,
      sequence: sequence
    }, payload]

  end

end