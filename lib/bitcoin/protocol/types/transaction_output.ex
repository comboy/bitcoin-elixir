defmodule Bitcoin.Protocol.Types.TransactionOutput do

  alias Bitcoin.Protocol.Types.Integer

  defstruct value: 0, # Transaction Value (in satoshis)
            pk_script: <<>> # Usually contains the public key as a Bitcoin script setting up conditions to claim this output.

  @type t :: %__MODULE__{
    value: non_neg_integer,
    pk_script: bitstring
  }

  def parse_stream(data) do

    <<value::unsigned-little-integer-size(64), payload :: binary>> = data
    [pk_script_size, payload] = Integer.parse_stream(payload)
    <<pk_script :: bytes-size(pk_script_size), payload :: binary >> = payload

    [%__MODULE__{
      value: value,
      pk_script: pk_script
    }, payload]

  end

  def serialize(%__MODULE__{} = s) do
    << s.value :: unsigned-little-integer-size(64) >>
    <> (s.pk_script |> byte_size |> Integer.serialize)
    <> s.pk_script
  end

end
