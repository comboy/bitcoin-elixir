defmodule Bitcoin.Protocol.Messages.AlertTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Alert

  test "parses the alert payload" do
    payload = <<"\xAC\x01\x00\x00\x00o\xF2cO\x00\x00\x00\x00k\"EQ\x00\x00\x00\x00\xF4\x03\x00\x00\xF2\x03\x00\x00\x00`\xEA\x00\x00`\xEA\x00\x00\x03\x11/Satoshi:0.6.0.3/\x0F/Satoshi:0.6.0/\x12/bitcoin-qt:0.6.0/\x88\x13\x00\x00\x00JURGENT: security fix for Bitcoin-Qt on Windows: http://bitcoin.org/critfix\x00H0F\x02!\x00\xB7\xB1o\x86\x0F\x9EZ\x87bt\xAE\xB7$u\xD2\xDE\xC3\x86j\xA7\xAF\x82\xAD\x97\\\x83Qd\xA9\x97\xA7\x16\x02!\x00\x86\xB4\x18)\xCB\x84\xBE\xD2\x86\x10\x82G\xBE\xBF;\xE9{\xD9\xB3\x1E\xB4/g\xB4\xD33\xCE\x8B\x1D}\xF8^"::binary>>

    alert = Alert.parse(payload)

    assert alert.version == 1
    assert alert.cancel == 1010
    assert alert.comment == ""
    assert alert.expiration == 1363485291
    assert alert.id == 1012
    assert alert.max_ver == 60000
    assert alert.min_ver == 60000
    assert alert.relay_until == 1331950191
    assert alert.reserved == ""
    assert alert.set_cancel == []
    assert alert.set_sub_ver == ["/Satoshi:0.6.0.3/", "/Satoshi:0.6.0/", "/bitcoin-qt:0.6.0/"]
    assert alert.status_bar == "URGENT: security fix for Bitcoin-Qt on Windows: http://bitcoin.org/critfix"

    payload = <<"s\x01\x00\x00\x007f@O\x00\x00\x00\x00\xB3\x05CO\x00\x00\x00\x00\xF2\x03\x00\x00\xF1\x03\x00\x00\x00\x10\'\x00\x00H\xEE\x00\x00\x00d\x00\x00\x00\x00FSee bitcoin.org/feb20 if you have trouble connecting after 20 February\x00G0E\x02!\x00\x83\x89\xDFE\xF0p?9\xEC\x8C\x1C\xC4,\x13\x81\x0F\xFC\xAE\x14\x99[\xB6H4\x02\x19\xE3S\xB6;S\xEB\x02 \t\xECe\xE1\xC1\xAA\xEE\xC1\xFD3LkhK\xDE+?W0`\xD5\xB7\f:Fr3&\xE4\xE8\xA4\xF1"::binary>>

    alert = Alert.parse(payload)

    assert alert.version == 1
    assert alert.cancel == 1009
    assert alert.comment == ""
    assert alert.expiration == 1329792435
    assert alert.id == 1010
    assert alert.max_ver == 61000
    assert alert.min_ver == 10000
    assert alert.relay_until == 1329620535
    assert alert.reserved == ""
    assert alert.set_cancel == []
    assert alert.set_sub_ver == []
    assert alert.status_bar == "See bitcoin.org/feb20 if you have trouble connecting after 20 February"
  end

  test "parses array of ints propely" do
    payload = "F9BEB4D9616C65727400000000000000A80000001BF9AAEA60010000000000000000000000FFFFFF7F00000000FFFFFF7FFEFFFF7F01FFFFFF7F00000000FFFFFF7F00FFFFFF7F002F555247454E543A20416C657274206B657920636F6D70726F6D697365642C2075706772616465207265717569726564004630440220653FEBD6410F470F6BAE11CAD19C48413BECB1AC2C17F908FD0FD53BDC3ABD5202206D0E9C96FE88D4A0F01ED9DEDAE2B6F9E00DA94CAD0FECAAE66ECF689BF71B50" |> Base.decode16!

    struct = %Alert{
      cancel: 2147483646,
      comment: "",
      expiration: 2147483647,
      id: 2147483647,
      max_ver: 2147483647,
      min_ver: 0,
      payload: "010000000000000000000000FFFFFF7F00000000FFFFFF7FFEFFFF7F01FFFFFF7F00000000FFFFFF7F00FFFFFF7F002F555247454E543A20416C657274206B657920636F6D70726F6D697365642C207570677261646520726571756972656400" |> Base.decode16!,
      priority: 2147483647,
      relay_until: 0,
      reserved: "",
      set_cancel: [2147483647],
      set_sub_ver: [],
      signature: "30440220653FEBD6410F470F6BAE11CAD19C48413BECB1AC2C17F908FD0FD53BDC3ABD5202206D0E9C96FE88D4A0F01ED9DEDAE2B6F9E00DA94CAD0FECAAE66ECF689BF71B50" |> Base.decode16!,
      status_bar: "URGENT: Alert key compromised, upgrade required",
      version: 1
    }

    assert Bitcoin.Protocol.Message.parse(payload).payload.message == struct
  end

end
