defmodule Bitcoin.Protocol.Messages.AddrTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Addr
  alias Bitcoin.Protocol.Types.NetworkAddress

  test "addr message with 1 address" do
    payload = Base.decode16!("01" <> # 1 address in this message
                             "E215104D" <> # Mon Dec 20 21:50:10 EST 2010 (only when version is >= 31402)
                             "0100000000000000" <> # 1 (NODE_NETWORK service - see version message)
                             "00000000000000000000FFFF0A000001" <> # IPv4: 10.0.0.1, IPv6: ::ffff:10.0.0.1 (IPv4-mapped IPv6 address)
                             "208D") # port 8333
    struct = %Addr{
             address_list: [
               %NetworkAddress{
                 address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
                 port: 8333,
                 services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                 time: 1292899810}
               ]
           }

    assert Addr.parse(payload) == struct
    assert Addr.serialize(struct) == payload
  end

  test "addr message with 2 addresses" do
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
    struct = %Addr{
             address_list: [
               %NetworkAddress{
                 address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 1>>,
                 port: 8333,
                 services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                 time: 1292899810},
               %NetworkAddress{
                 address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 10, 0, 0, 2>>,
                 port: 8334,
                 services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
                 time: 1292899810}
             ]
           }

    assert Addr.parse(payload) == struct
    assert Addr.serialize(struct) == payload
  end

end
