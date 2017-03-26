defmodule BitcoinTest.Protocol.Types.NetworkAddressTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.NetworkAddress

  test "IPv4 Addresses w/o Time (for Version Message)" do

    binary = Base.decode16!("0100000000000000" <> # - 1 (NODE_NETWORK service - see version message)
                               "00000000000000000000FFFF0A000001" <> # - IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                               "208D") # - port 8333"

    struct = %Bitcoin.Protocol.Types.NetworkAddress{
             address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
             port: 8333,
             services: <<1, 0, 0, 0, 0, 0, 0, 0>>
           } 

    assert NetworkAddress.parse_version(binary) == struct
    assert NetworkAddress.serialize_version(struct) == binary

  end

    test "IPv4 Addresses w/ Time" do

      binary = Base.decode16!("E215104D" <> # - Mon Dec 20 21:50:10 EST 2010 (only when version is >= 31402)
                                 "0100000000000000" <> # - 1 (NODE_NETWORK service - see version message)
                                 "00000000000000000000FFFF0A000001" <> # - IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                                 "208D") # - port 8333"

      struct = %Bitcoin.Protocol.Types.NetworkAddress{
               time: 1292899810,
               address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
               port: 8333,
               services: <<1, 0, 0, 0, 0, 0, 0, 0>>
             }

      assert NetworkAddress.parse(binary) == struct
      assert NetworkAddress.serialize(struct) == binary

    end

end
