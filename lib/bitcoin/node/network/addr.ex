defmodule Bitcoin.Node.Network.Addr do
  @moduledoc """
    Keeps database of known network nodes.

    Dummy version. Would be nice to switch to some dedicated struct from Protocol.NetworkAddress.
    We may want to keep fields like last connection try times, last successful connection time,
    maybe some score (e.g. higher for addrs from trusted seeds). Score could also help with blacklisting
    nodes from which we detected abuse.
  """
  use GenServer

  require Lager

  alias Bitcoin.Protocol.Types.NetworkAddress

  # Ignaring opts which contains modules list since we don't currently need it
  def start_link(_opts \\ %{}), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def add(%NetworkAddress{} = addr), do: GenServer.cast(__MODULE__, {:add, addr})
  def get, do: GenServer.call(__MODULE__, :get)
  def count, do: GenServer.call(__MODULE__, :count)
  def clear, do: GenServer.cast(__MODULE__, :clear)

  def handle_cast({:add, %NetworkAddress{} = addr}, addrs) do
    Lager.debug("adding new network address #{addr.address |> :inet.ntoa}")
    existing = addrs[addr.address]
    # If we already have this address, update timestamp if it's older
    # TODO check if timestamp is not in the future
    # TODO mark seed addresses somehow and be nice to them (i.e. disconnect after fetching addrs)
    if !existing || existing && existing.time< addr.time do
      {:noreply, addrs |> Map.put(addr.address, addr)}
    else
      {:noreply, addrs}
    end
  end

  def handle_cast(:clear, _addrs) do
    {:noreply, %{}}
  end

  def handle_call(:count, _from, addrs) do
    {:reply, addrs |> Map.size, addrs}
  end

  def handle_call(:get, _from, addrs) when addrs == %{}, do: {:reply, nil, addrs}
  def handle_call(:get, _from, addrs) do
    {:reply, addrs |> Map.values |> Enum.random, addrs}
  end

end
