defmodule BitcoinTest.Protocol.MessageTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Message

  test "parsing message header w/o payload" do
    alert_payload = :binary.list_to_bin('\xAC\x01\x00\x00\x00o\xF2cO\x00\x00\x00\x00k\"EQ\x00\x00\x00\x00\xF4\x03\x00\x00\xF2\x03\x00\x00\x00`\xEA\x00\x00`\xEA\x00\x00\x03\x11/Satoshi:0.6.0.3/\x0F/Satoshi:0.6.0/\x12/bitcoin-qt:0.6.0/\x88\x13\x00\x00\x00JURGENT: security fix for Bitcoin-Qt on Windows: http://bitcoin.org/critfix\x00H0F\x02!\x00\xB7\xB1o\x86\x0F\x9EZ\x87bt\xAE\xB7$u\xD2\xDE\xC3\x86j\xA7\xAF\x82\xAD\x97\\\x83Qd\xA9\x97\xA7\x16\x02!\x00\x86\xB4\x18)\xCB\x84\xBE\xD2\x86\x10\x82G\xBE\xBF;\xE9{\xD9\xB3\x1E\xB4/g\xB4\xD33\xCE\x8B\x1D}\xF8^')
    message_data = << 0xF9, 0xBE, 0xB4, 0xD9 >> <> # bitcoin main net identifier, magic value 0xD9B4BEF9
                      "alert" <> << 0, 0, 0, 0, 0, 0, 0, # command, in this case, 'alert', NUL-padded to 12 bytes
                      246, 0, 0, 0, # payload length, in this case, one byte
                      0, 0, 0, 0 # checksum, in this case, invalid, sha256(sha256(payload)) first four bytes
                   >> <> alert_payload

    assert %Bitcoin.Protocol.Message.Header{
               checksum: 0,
               command: "alert" <> <<0, 0, 0, 0, 0, 0, 0>>,
               network_identifier: 3652501241,
               payload_size_bytes: 246
           } ==
             Message.parse(message_data).header
  end

  test "parsing message header w/ alert payload" do
    alert_payload = :binary.list_to_bin('\xAC\x01\x00\x00\x00o\xF2cO\x00\x00\x00\x00k\"EQ\x00\x00\x00\x00\xF4\x03\x00\x00\xF2\x03\x00\x00\x00`\xEA\x00\x00`\xEA\x00\x00\x03\x11/Satoshi:0.6.0.3/\x0F/Satoshi:0.6.0/\x12/bitcoin-qt:0.6.0/\x88\x13\x00\x00\x00JURGENT: security fix for Bitcoin-Qt on Windows: http://bitcoin.org/critfix\x00H0F\x02!\x00\xB7\xB1o\x86\x0F\x9EZ\x87bt\xAE\xB7$u\xD2\xDE\xC3\x86j\xA7\xAF\x82\xAD\x97\\\x83Qd\xA9\x97\xA7\x16\x02!\x00\x86\xB4\x18)\xCB\x84\xBE\xD2\x86\x10\x82G\xBE\xBF;\xE9{\xD9\xB3\x1E\xB4/g\xB4\xD33\xCE\x8B\x1D}\xF8^')
    parsed_alert = Bitcoin.Protocol.Messages.Alert.parse(alert_payload)
    message_data = << 0xF9, 0xBE, 0xB4, 0xD9 >> <> # bitcoin main net identifier, magic value 0xD9B4BEF9
                      "alert" <> << 0, 0, 0, 0, 0, 0, 0, # command, in this case, 'alert', NUL-padded to 12 bytes
                      246, 0, 0, 0, # payload length, in this case, one byte
                      0, 0, 0, 0, # checksum, in this case, invalid, sha256(sha256(payload)) first four bytes
                   >> <> alert_payload
    assert parsed_alert == Message.parse(message_data).payload
  end

end