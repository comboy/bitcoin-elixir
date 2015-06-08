defmodule Bitcoin.Protocol.Types.Outpoint do

  defstruct hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32] - The hash of the referenced transaction.
            index: 0 # The index of the specific output in the transaction. The first output is 0, etc.

  @type t :: %Bitcoin.Protocol.Types.Outpoint{
    hash: bitstring,
    index: non_neg_integer
  }

  def parse_stream(<<hash::bytes-size(32), index::unsigned-little-integer-size(32), remainder::binary>>) do
    [%Bitcoin.Protocol.Types.Outpoint{
      hash: hash,
      index: index
    }, remainder]
  end

  def parse(<<hash::bytes-size(32), index::unsigned-little-integer-size(32)>>) do
    %Bitcoin.Protocol.Types.Outpoint{
      hash: hash,
      index: index
    }
  end

end