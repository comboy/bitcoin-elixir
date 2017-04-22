defmodule Bitcoin.Protocol.Types.Outpoint do

  defstruct hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32] - The hash of the referenced transaction.
            index: 0 # The index of the specific output in the transaction. The first output is 0, etc.

  @type t :: %__MODULE__{
    hash: bitstring,
    index: non_neg_integer
  }

  defimpl Inspect, for: __MODULE__ do
    def inspect(data, _opts) do
      "%Outpoint{ ##{data.index} hash: #{data.hash |> Base.encode16} }"
    end
  end

  def parse_stream(<<hash::bytes-size(32), index::unsigned-little-integer-size(32), remainder::binary>>) do
    {%__MODULE__{
      hash: hash,
      index: index
    }, remainder}
  end

  def parse(<<hash::bytes-size(32), index::unsigned-little-integer-size(32)>>) do
    %__MODULE__{
      hash: hash,
      index: index
    }
  end

  def serialize(%__MODULE__{} = s) do
    <<
      s.hash :: bytes-size(32),
      s.index :: unsigned-little-integer-size(32)
    >>
  end

end
