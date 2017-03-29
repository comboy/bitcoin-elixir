defmodule Bitcoin.Node.Network.AddrTest do
  use ExUnit.Case

  alias Bitcoin.Node.Network.Addr
  alias Bitcoin.Protocol.Types.NetworkAddress, as: NA

  test "addrs management" do
    {:ok, _pid} = Addr.start_link
    Addr.clear()
    assert Addr.count() == 0
    assert Addr.get() == nil
    na1 = %NA{address: {1,2,3,4}}
    na2 = %NA{address: {1,2,3,5}}
    na1 |> Addr.add
    assert Addr.count() == 1
    assert Addr.get() == na1
    na2 |> Addr.add
    assert Addr.count() == 2
    # couldn't figure out how to force :rand.seed (it seems to be local per process?)
    results = (1..100) |> Enum.reduce(MapSet.new, fn(_x, r) -> r |> MapSet.put(Addr.get()) end)
    assert results == MapSet.new([na1, na2])
  end
end
