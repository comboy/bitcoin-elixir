defmodule Bitcoin.Protocol.Types.BlockHeader do

  defstruct version: 0, # Block version information, based upon the software version creating this block
            previous_block: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32], The hash value of the previous block this particular block references
            merkle_root: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, # char[32], The reference to a Merkle tree collection which is a hash of all transactions related to this block
            timestamp: 0, # uint32_t, A Unix timestamp recording when this block was created (Currently limited to dates before the year 2106!)
            bits: 0, # uint32_t, The calculated difficulty target being used for this block
            nonce: 0, # uint32_t, The nonce used to generate this block… to allow variations of the header and compute different hashes
            transaction_count: 0 # count - Bitcoin.Protocol.Types.Integer, number of transaction entries in this block

  @type t :: %Bitcoin.Protocol.Types.BlockHeader{
    version: non_neg_integer,
    previous_block: bitstring,
    merkle_root: bitstring,
    timestamp: non_neg_integer,
    bits: non_neg_integer,
    nonce: non_neg_integer,
    transaction_count: non_neg_integer
  }

  def parse(data) do
    <<version::unsigned-little-integer-size(32),
      previous_block::bytes-size(32),
      merkle_root::bytes-size(32),
      timestamp::unsigned-little-integer-size(32),
      bits::unsigned-little-integer-size(32),
      nonce::unsigned-little-integer-size(32),
      payload::binary>> = data

    [transaction_count, _] = Bitcoin.Protocol.Types.Integer.parse_stream(payload)

    %Bitcoin.Protocol.Types.BlockHeader{
      version: version,
      previous_block: previous_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      transaction_count: transaction_count
    }
  end

  def parse_stream(data) do
    <<version::unsigned-little-integer-size(32),
      previous_block::bytes-size(32),
      merkle_root::bytes-size(32),
      timestamp::unsigned-little-integer-size(32),
      bits::unsigned-little-integer-size(32),
      nonce::unsigned-little-integer-size(32),
      payload::binary>> = data

    [transaction_count, payload] = Bitcoin.Protocol.Types.Integer.parse_stream(payload)

    [%Bitcoin.Protocol.Types.BlockHeader{
        version: version,
        previous_block: previous_block,
        merkle_root: merkle_root,
        timestamp: timestamp,
        bits: bits,
        nonce: nonce,
        transaction_count: transaction_count
     }, payload]
  end

end
