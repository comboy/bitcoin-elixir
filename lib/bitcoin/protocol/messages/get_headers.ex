defmodule Bitcoin.Protocol.Messages.GetHeaders do

  @moduledoc """
    Return a headers packet containing the headers of blocks starting right after the last known hash in the block
    locator object, up to hash_stop or 2000 blocks, whichever comes first. To receive the next block headers, one needs
    to issue getheaders again with a new block locator object. The getheaders command is used by thin clients to
    quickly download the block chain where the contents of the transactions would be irrelevant (because they are not
    ours). Keep in mind that some clients may provide headers of blocks which are invalid if the block locator object
    contains a hash on the invalid branch.

    For the block locator object in this packet, the same rules apply as for the getblocks packet.

    https://en.bitcoin.it/wiki/Protocol_specification#getheaders
  """

  alias Bitcoin.Protocol.Types.Integer

  defstruct version: 0, # the protocol version
            block_locator_hashes: [], # block locator object; newest back to genesis block (dense to start, but then sparse)
            hash_stop: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>> # hash of the last desired block; set to zero to get as many headers as possible (up to 2000)

  @type t :: %__MODULE__{
    version: non_neg_integer,
    block_locator_hashes: list,
    hash_stop: bitstring
  }

  def parse(data) do

    <<version :: unsigned-little-integer-size(32), payload :: binary>> = data

    [count, payload] = Integer.parse_stream(payload)

    [block_locator_hashes, payload] = Enum.reduce(1..count, [[], payload], fn (_, [collection, payload]) ->
      <<element :: bytes-size(32), payload :: binary>> = payload
      [collection ++ [element], payload]
    end)

    << hash_stop :: bytes-size(32) >> = payload

    %__MODULE__{
      version: version,
      block_locator_hashes: block_locator_hashes,
      hash_stop: hash_stop
    }

  end

  def serialize(%__MODULE__{} = s) do
    << 
      s.version :: unsigned-little-integer-size(32),
    >> <>
      Integer.serialize(s.block_locator_hashes |> Enum.count)
    <> (
      s.block_locator_hashes |> Enum.reduce(<<>>, &(&2 <> &1))
    ) <>
    <<
      s.hash_stop :: bytes-size(32)
    >>
  end

end
