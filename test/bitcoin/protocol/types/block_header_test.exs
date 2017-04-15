defmodule BitcoinTest.Protocol.Types.BlockHeader do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.BlockHeader

  test "block header" do
    # Hexdump source: https://bitcoin.org/en/developer-reference#merkleblock
    # Tx 
    payload = Base.decode16!(
      "01000000" <> # Block version: 1
      "82BB869CF3A793432A66E826E05A6FC3" <>
      "7469F8EFB7421DC88067010000000000" <> # Hash of previous block's header
      "7F16C5962E8BD963659C793CE370D95F" <>
      "093BC7E367117B3C30C1F8FDD0D97287" <> # Merkle root
      "76381B4D" <> # Time: 1293629558
      "4C86041B" <> # nBits: 0x04864c * 256**(0x1b-3)
      "554B8529" <>  #Nonce
      "00") # Transaction count: 0

    struct = %BlockHeader{
      version: 1,
      bits: 453281356,
      previous_block: <<130, 187, 134, 156, 243, 167, 147, 67, 42, 102, 232, 38, 224, 90, 111, 195, 116, 105, 248, 239, 183, 66, 29, 200, 128, 103, 1, 0, 0, 0, 0,  0>>,
      merkle_root: <<127, 22, 197, 150, 46, 139, 217, 99, 101, 156, 121, 60, 227, 112, 217, 95, 9, 59, 199, 227, 103, 17, 123, 60, 48, 193, 248, 253, 208, 217, 114, 135>>, 
      timestamp: 1293629558,
      nonce: 696601429,
      transaction_count: 0
    }

    assert BlockHeader.parse(payload) == struct
    assert BlockHeader.serialize(struct) == payload
  end

end

