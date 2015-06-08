defmodule Bitcoin.Protocol.Messages.AddrTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Addr

  test "parses the addr message with 1 address" do
    payload = Base.decode16!("01" <> # 1 address in this message
                             "E215104D" <> # Mon Dec 20 21:50:10 EST 2010 (only when version is >= 31402)
                             "0100000000000000" <> # 1 (NODE_NETWORK service - see version message)
                             "00000000000000000000FFFF0A000001" <> # IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                             "208D") # port 8333
    assert %Bitcoin.Protocol.Messages.Addr{
             address_list: [
               %Bitcoin.Protocol.Types.NetworkAddress{
                 address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
                 port: 8333,
                 services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                 time: 1292899810}
               ]
           }== Addr.parse(payload)
  end

    test "parses the addr message with 2 addresses" do
      payload = Base.decode16!("02" <> # 1 address in this message
                               # Address 1
                               "E215104D" <> # Mon Dec 20 21:50:10 EST 2010 (only when version is >= 31402)
                               "0100000000000000" <> # 1 (NODE_NETWORK service - see version message)
                               "00000000000000000000FFFF0A000001" <> # IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                               "208D" <> # port 8333
                               # Address 2
                               "E215104D" <> # Mon Dec 20 21:50:10 EST 2010 (only when version is >= 31402)
                               "0100000000000000" <> # 1 (NODE_NETWORK service - see version message)
                               "00000000000000000000FFFF0A000002" <> # IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                               "208E") # port 8334
      assert %Bitcoin.Protocol.Messages.Addr{
               address_list: [
                 %Bitcoin.Protocol.Types.NetworkAddress{
                   address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
                   port: 8333,
                   services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                   time: 1292899810},
                 %Bitcoin.Protocol.Types.NetworkAddress{
                   address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 2>>,
                   port: 8334,
                   services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                   time: 1292899810}
               ]
             } == Addr.parse(payload)
    end

end