defmodule Bitcoin.Protocol.Messages.HeadersTest do

  use ExUnit.Case
  alias Bitcoin.Protocol.Messages.Headers

  test "headers message" do
    payload = Base.decode16!(
      "01" <> # Header count: 1
      "02000000" <> # Block version: 2
      "B6FF0B1B1680A2862A30CA44D346D9E8" <>
      "910D334BEB48CA0C0000000000000000" <> # Hash of previous block's header
      "9D10AA52EE949386CA9385695F04EDE2" <>
      "70DDA20810DECD12BC9B048AAAB31471" <> # Merkle root
      "24D95A54" <> # Unix time: 1415239972
      "30C31B18" <> # Target (bits)
      "FE9F0864" <> # Nonce
      "00" # Transaction count (0x00)
    )

    struct = %Headers{
      headers: [
        %Bitcoin.Protocol.Types.BlockHeader{
          bits: 404472624,
          merkle_root: <<157, 16, 170, 82, 238, 148, 147, 134, 202, 147, 133, 105, 95, 4, 237, 226, 112, 221, 162, 8, 16, 222, 205, 18, 188, 155, 4, 138, 170, 179, 20, 113>>,
          previous_block: <<182, 255, 11, 27, 22, 128, 162, 134, 42, 48, 202, 68, 211, 70, 217, 232, 145, 13, 51, 75, 235, 72, 202, 12, 0, 0, 0, 0, 0, 0, 0, 0>>,
          nonce: 1678286846,
          timestamp: 1415239972, transaction_count: 0, version: 2
        }
      ]
    }

    assert Headers.parse(payload) == struct
    assert Headers.serialize(struct) == payload
  end
end
