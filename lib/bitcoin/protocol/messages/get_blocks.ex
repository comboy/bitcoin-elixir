defmodule Bitcoin.Protocol.Messages.GetBlocks do

  @moduledoc """
    Return an inv packet containing the list of blocks starting right after the last known hash in the block locator
    object, up to hash_stop or 500 blocks, whichever comes first.

    The locator hashes are processed by a node in the order as they appear in the message. If a block hash is found in
    the node's main chain, the list of its children is returned back via the inv message and the remaining locators are
    ignored, no matter if the requested limit was reached, or not.

    To receive the next blocks hashes, one needs to issue getblocks again with a new block locator object. Keep in mind
    that some clients may provide blocks which are invalid if the block locator object contains a hash on the invalid
    branch.

    To create the block locator hashes, keep pushing hashes until you go back to the genesis block.
    After pushing 10 hashes back, the step backwards doubles every loop.

    Note that it is allowed to send in fewer known hashes down to a minimum of just one hash. However, the purpose of
    the block locator object is to detect a wrong branch in the caller's main chain. If the peer detects that you are
    off the main chain, it will send in block hashes which are earlier than your last known block. So if you just send
    in your last known hash and it is off the main chain, the peer starts over at block #1.

    https://en.bitcoin.it/wiki/Protocol_specification#getblocks
  """

  import Bitcoin.Protocol

  defstruct version: 0, # the protocol version
            block_locator_hashes: [], # block locator object; newest back to genesis block (dense to start, but then sparse)
            hash_stop: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>> # hash of the last desired block; set to zero to get as many blocks as possible (up to 500)

  @type t :: %__MODULE__{
    version: non_neg_integer,
    block_locator_hashes: list,
    hash_stop: bitstring
  }

  def parse(data) do

    << version :: unsigned-little-integer-size(32), payload :: binary>> = data

    {block_locator_hashes, payload} = payload |> collect_items(:hash)

    << hash_stop :: bytes-size(32) >> = payload

    %__MODULE__{
      version: version,
      block_locator_hashes: block_locator_hashes,
      hash_stop: hash_stop
    }

  end

  def serialize(%__MODULE__{} = s) do
    << s.version :: unsigned-little-integer-size(32) >>
    <>
    ( s.block_locator_hashes |> serialize_items )
    <>
    << s.hash_stop :: bytes-size(32) >>
  end


end
