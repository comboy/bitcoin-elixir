defmodule Bitcoin.Protocol.Messages.PingTest do
  use ExUnit.Case
  alias Bitcoin.Protocol.Messages.Ping

  test "parses the ping message" do
    nonce = 123456790987654321

    payload = <<177, 196, 237, 27, 76, 155, 182, 1>> # 64 bit int nonce

    struct = %Ping{nonce: nonce}

    assert Ping.parse(payload) == struct
    assert Ping.serialize(struct) == payload
  end
end
