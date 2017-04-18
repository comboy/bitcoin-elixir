defmodule Bitcoin.Node.Network.ConnectionManager do

  # Reagent connection handler
  defmodule ReagentHandler do
    use Reagent
    use Bitcoin.Common

    def handle(%Reagent.Connection{socket: socket}) do
      {:ok, pid} = @modules[:peer].start(socket)
      # Potential issue:
      # If the connection gets closed after Peer.start but before switching the controlling process
      # then probably Peer will never receive _:tcp_closed. Not sure if we need to care because
      # it should just timout then
      socket |> :gen_tcp.controlling_process(pid)
      socket |> :inet.setopts(active: true)
      :ok
    end
  end

  use Bitcoin.Common
  use GenServer

  require Logger

  alias Bitcoin.Protocol.Types.NetworkAddress

  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def connect(ip, port \\ 8333), do: GenServer.cast(__MODULE__, {:connect, ip, port})
  def register_peer(), do: GenServer.call(__MODULE__, :register_peer)
  def peers, do: GenServer.call(__MODULE__, :peers)

  def init(_) do
    state = %{
      config: Bitcoin.Node.config(),
      peers: []
    }

    {:ok, _pid} = Reagent.start_link(ReagentHandler, port: state.config[:listen_port])

    # If connect option is specified in the node config, only connect to the specified peers
    case state.config[:connect] do
      nil -> self() |> send(:periodical_connectivity_check)
      # TODO allow ip:port, actually it will only accept IP as a tuple currently
      list -> list |> Enum.each(fn ip -> connect(ip) end)
    end

    {:ok, state}
  end

  def handle_info(:periodical_connectivity_check, state) do
    self() |> send(:check_connectivity)
    self() |> Process.send_after(:periodical_connectivity_check, 10_000)
    {:noreply, state}
  end

  def handle_info(:check_connectivity, state) do
    num_conn = length(state.peers)
    max_conn = state.config[:max_connections]
    Logger.info("[CM] #{num_conn} peers connected")

    # TODO we want to differentiate between outbound_max_connections and max_connections
    # E.g. bitcoin-core behavior is that it won't have more than 8 outbound connections
    # regardless of the max-connections setting.
    # ALso, there's no hard limit on max_connections currently, Reagent limit should be
    # dynamic plus we can go over limit if some peer connection is already in progress
    # and we add another one
    if num_conn < max_conn do
      (0..(max_conn - num_conn)) |> Enum.each(fn _ ->
        state |> add_peer()
      end)
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, peer, _reason}, state) do
    Logger.info("[CM] unregistered peer #{peer |> inspect}")
    self() |> send(:check_connectivity)
    {:noreply, state |> Map.put(:peers, state.peers |> List.delete(peer))}
  end

  def handle_call(:peers, _from, state) do
    {:reply, state.peers, state}
  end

  def handle_call(:register_peer, {peer, _ref}, state) do
    Logger.info("[CM] registered peer #{peer |> inspect}")
    state = state |> Map.put(:peers, [peer | state.peers])
    Process.monitor(peer)
    {:reply, :ok, state}
  end

  def handle_cast({:connect, ip, port}, state) do
    @modules[:peer].start(ip, port)
    {:noreply, state}
  end

  def add_peer(_state) do
    case @modules[:addr].get do
      %NetworkAddress{address: ip, port: port} ->
        connect(ip, port)
      nil ->
        Bitcoin.Node.Network.find_more_addrs()
    end
  end

end
