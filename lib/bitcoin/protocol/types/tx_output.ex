defmodule Bitcoin.Protocol.Types.TxOutput do

  alias Bitcoin.Protocol.Types.VarString

  defstruct value: 0, # Transaction Value (in satoshis)
            pk_script: <<>> # Usually contains the public key as a Bitcoin script setting up conditions to claim this output.

  @type t :: %__MODULE__{
    value: non_neg_integer,
    pk_script: bitstring
  }

  defimpl Inspect, for: __MODULE__ do
    def inspect(data, _opts) do
      "%Out{ #{data.value} -> #{data.pk_script |> Base.encode16} }"
    end
  end

  def parse_stream(payload) do
    << value::unsigned-little-integer-size(64), payload :: binary >> = payload
    [pk_script, payload] = VarString.parse_stream(payload)

    [%__MODULE__{
      value: value,
      pk_script: pk_script
    }, payload]
  end

  def serialize(%__MODULE__{} = s) do
    << s.value :: unsigned-little-integer-size(64) >>
    <> (s.pk_script |> VarString.serialize)
  end

end
