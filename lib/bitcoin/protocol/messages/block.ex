defmodule Bitcoin.Protocol.Messages.Block do

  @moduledoc """
    The block message is sent in response to a getdata message which requests transaction information from a block hash.

    The SHA256 hash that identifies each block (and which must have a run of 0 bits) is calculated from the first 6
    fields of this structure (version, prev_block, merkle_root, timestamp, bits, nonce, and standard SHA256 padding,
    making two 64-byte chunks in all) and not from the complete block. To calculate the hash, only two chunks need to
    be processed by the SHA256 algorithm. Since the nonce field is in the second chunk, the first chunk stays constant
    during mining and therefore only the second chunk needs to be processed. However, a Bitcoin hash is the hash of the
    hash, so two SHA256 rounds are needed for each mining iteration. See Block hashing algorithm
    <https://en.bitcoin.it/wiki/Block_hashing_algorithm> for details and an example.

    https://en.bitcoin.it/wiki/Protocol_documentation#block
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Messages.Tx

  defstruct version: 0, # Block version information, based upon the software version creating this block
            previous_block: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32], The hash value of the previous block this particular block references
            merkle_root: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32], The reference to a Merkle tree collection which is a hash of all transactions related to this block
            timestamp: 0, # uint32_t, A Unix timestamp recording when this block was created (Currently limited to dates before the year 2106!)
            bits: 0, # uint32_t, The calculated difficulty target being used for this block
            nonce: 0, # uint32_t, The nonce used to generate this block… to allow variations of the header and compute different hashes
            transactions: [] # count - Bitcoin.Protocol.Types.Integer, number of transaction entries in this block, [Transaction]

  @type t :: %Bitcoin.Protocol.Messages.Block{
    version: integer,
    previous_block: bitstring,
    merkle_root: bitstring,
    timestamp: non_neg_integer,
    bits: non_neg_integer,
    nonce: non_neg_integer,
    transactions: [Tx]
  }

  def parse(data) do

    <<version::little-integer-size(32),
      previous_block::bytes-size(32),
      merkle_root::bytes-size(32),
      timestamp::unsigned-little-integer-size(32),
      bits::unsigned-little-integer-size(32),
      nonce::unsigned-little-integer-size(32),
      payload::binary>> = data

    [transaction_count, payload] = Integer.parse(payload)

    [transactions, _] = Enum.reduce(1..transaction_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = Tx.parse(payload)
      [collection ++ [element], payload]
    end)

    %Bitcoin.Protocol.Messages.Block{
      version: version,
      previous_block: previous_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      transactions: transactions
    }

  end

end
