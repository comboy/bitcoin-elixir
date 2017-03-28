defmodule Bitcoin.Protocol.Messages.VersionTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Version

  test "parses the version payload for version 0.3.19" do
    payload = Base.decode16!("9C7C0000" <> # 31900 (version 0.3.19)
                             "0100000000000000" <> # 1 (NODE_NETWORK services)
                             "E615104D00000000" <> # Mon Dec 20 21:50:14 EST 2010 . 1292899814 Unix Epoch
                             "010000000000000000000000000000000000FFFF0A000001208D" <> # Recipient address info - see Network Address
                             "010000000000000000000000000000000000FFFF0A000002208D" <> # Sender address info - see Network Address
                             "DD9D202C3AB45713" <> # Node random unique ID
                             "00" <> # "" sub-version string (string is 0 bytes long)
                             "55810100") # Last block sending node has is block #98645

    assert %Bitcoin.Protocol.Messages.Version{
             address_of_receiving_node: %Bitcoin.Protocol.Types.NetworkAddress{
               services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
               address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
               port: 8333
             },
             address_of_sending_node: %Bitcoin.Protocol.Types.NetworkAddress{
               services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
               address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 2>>,
               port: 8333
             },
             nonce: 1393780771635895773,
             relay: false,
             services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
             start_height: 98645,
             timestamp: 1292899814,
             user_agent: "",
             version: 31900
           } ==
             Version.parse(payload)
  end

  test "parses the version payload for protocol version 60002" do
    payload = Base.decode16!("62EA0000" <> # 60002 (protocol version 60002)
                             "0100000000000000" <> # 1 (NODE_NETWORK services)
                             "11B2D05000000000" <> # Tue Dec 18 10:12:33 PST 2012
                             "010000000000000000000000000000000000FFFF000000000000" <> # Recipient address info - see Network Address
                             "010000000000000000000000000000000000FFFF000000000000" <> # Sender address info - see Network Address
                             "3B2EB35D8CE61765" <> # Node random unique ID
                             "0F2F5361746F7368693A302E372E322F" <> # "/Satoshi:0.7.2/" sub-version string (string is 15 bytes long)
                             "C03E0300" <> # Last block sending node has is block #212672
                             "01") # Enable Relay Fl

    assert %Bitcoin.Protocol.Messages.Version{
             address_of_receiving_node: %Bitcoin.Protocol.Types.NetworkAddress{
               services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
               address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 0, 0, 0, 0>>,
               port: 0
             },
             address_of_sending_node: %Bitcoin.Protocol.Types.NetworkAddress{
               services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
               address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 0, 0, 0, 0>>,
               port: 0
             },
             nonce: 7284544412836900411,
             relay: true,
             services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
             start_height: 212672,
             timestamp: 1355854353,
             user_agent: "/Satoshi:0.7.2/",
             version: 60002
           } ==
             Version.parse(payload)
  end

  test "version payload for protocol version 70002" do
    # Hexdump source: https://bitcoin.org/en/developer-reference#version
    payload = Base.decode16!("72110100" <> # Protocol version: 70002
                             "0100000000000000" <> # Services: NODE_NETWORK
                             "BC8F5E5400000000" <> # Epoch time: 1415483324
                             "0100000000000000" <> # Receiving node's services
                             "00000000000000000000FFFFC61B6409" <> #  Receiving node's IPv6 address
                             "208D" <>  # Receiving node's port number
                             "0100000000000000" <> # Transmitting node's services
                             "00000000000000000000FFFFCB0071C0" <> # Transmitting node's IPv6 address
                             "208D" <> # Transmitting node's port number
                             "128035CBC97953F8" <> # Nonce
                             "0F" <> # Bytes in user agent string: 15
                             "2F5361746F7368693A302E392E332F" <> # User agent: /Satoshi:0.9.2.1/
                             "CF050500" <> # Start height: 329167
                             "01") # Relay flag: true
    parsed_msg = %Bitcoin.Protocol.Messages.Version{
      address_of_receiving_node: %Bitcoin.Protocol.Types.NetworkAddress{
        address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 198, 27, 100, 9>>,
        port: 8333,
        services: <<1, 0, 0, 0, 0, 0, 0, 0>>
        },
      address_of_sending_node: %Bitcoin.Protocol.Types.NetworkAddress{
        address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 203, 0, 113, 192>>,
        port: 8333,
        services: <<1, 0, 0, 0, 0, 0, 0, 0>>
        },
      nonce: 17893779652077781010,
      relay: true,
      services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
      start_height: 329167,
      timestamp: 1415483324,
      user_agent: "/Satoshi:0.9.3/",
      version: 70002}

    # Test parsing
    assert Version.parse(payload) == parsed_msg

    # Test serialization
    assert Version.serialize(parsed_msg) == payload

    # Test parsing full message with header
    header = << 0xF9, 0xBE, 0xB4, 0xD9 >> <> # bitcoin main net identifier, magic value 0xD9B4BEF9
                     "version" <> << 0, 0, 0, 0, 0 >> <> # 'version' command
                   << byte_size(payload) :: unsigned-little-integer-size(32) >> <> # payload length, in this case, one byte
                   << 0, 0, 0, 0 >> # invalid checksum, update wehn implementde

    assert Bitcoin.Protocol.Message.parse(header <> payload).payload.message == parsed_msg

  end

end
