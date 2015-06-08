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

end