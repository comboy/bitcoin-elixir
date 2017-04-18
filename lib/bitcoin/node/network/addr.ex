defmodule Bitcoin.Node.Network.Addr do
  @moduledoc """
    Keeps database of known network nodes.

    Dummy version. Would be nice to switch to some dedicated struct from Protocol.NetworkAddress.
    We may want to keep fields like last connection try times, last successful connection time,
    maybe some score (e.g. higher for addrs from trusted seeds). Score could also help with blacklisting
    nodes from which we detected abuse.
  """

  @max_stored_addrs 1_000
  @persist_frequency 1*60_000 # 1 minute

  use GenServer

  require Logger

  alias Bitcoin.Protocol.Types.NetworkAddress

  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def add(%NetworkAddress{} = addr), do: GenServer.cast(__MODULE__, {:add, addr})
  def get, do: GenServer.call(__MODULE__, :get)
  def count, do: GenServer.call(__MODULE__, :count)
  def clear, do: GenServer.cast(__MODULE__, :clear)

  def init(_) do
    self() |> Process.send_after(:periodical_persistance, @persist_frequency)
    {:ok, load_persisted()}
  end

  # Periodical cleanup and saving to addrs to disk
  def handle_info(:periodical_persistance, addrs) do
    self() |> Process.send_after(:periodical_persistance, @persist_frequency)
    {:noreply, addrs |> cleanup |> persist}
  end

  # Try adding addr
  def handle_cast({:add, %NetworkAddress{} = addr}, addrs) do
    Logger.debug("adding new network address #{addr.address |> :inet.ntoa}")
    existing = addrs[addr.address]

    # If we already have this address, update timestamp if it's older
    if (!existing || existing && existing.time < addr.time) && valid?(addr) do
      {:noreply, addrs |> Map.put(addr.address, addr)}
    else
      {:noreply, addrs}
    end
  end

  # Remove all stored addrs
  def handle_cast(:clear, _addrs) do
    {:noreply, %{}}
  end

  # Total number of stored addrs
  def handle_call(:count, _from, addrs) do
    {:reply, addrs |> Map.size, addrs}
  end

  # Get random addr
  def handle_call(:get, _from, addrs) when addrs == %{}, do: {:reply, nil, addrs}
  def handle_call(:get, _from, addrs) do
    {:reply, addrs |> Map.values |> Enum.random, addrs}
  end

  defp valid?(%NetworkAddress{} = na), do: na.time <= Bitcoin.Node.timestamp()

  # Remove addresses above the limit, oldest first
  defp cleanup(addrs), do: addrs |> Enum.sort_by(fn {_k, v} -> v.time end) |> Enum.reverse |> Enum.take(@max_stored_addrs) |> Enum.into(%{})

  # Save addrs to disk
  # TODO upgrade state struct and only touch disk if there was some change since the last time
  defp persist(addrs) do
    :ok = filename() |> File.write(addrs |> :erlang.term_to_binary)
    addrs
  end

  # Load addrs stored on disk
  defp load_persisted do
    case filename() |> File.exists? do
      true -> File.read!(filename()) |> :erlang.binary_to_term
      false -> %{}
    end
  end

  # Filename where addrs are persisted
  defp filename, do: [Bitcoin.Node.config().data_directory, "known_addrs.dat"] |> Path.join

end
