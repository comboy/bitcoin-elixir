defmodule Bitcoin.Node.Network.ConnectionManager do
  use GenServer

  require Lager

  alias Bitcoin.Protocol.Types.NetworkAddress

  def start_link(%{modules: _modules} = opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def connect(ip, port), do: GenServer.cast(__MODULE__, {:connect, ip, port})
  def register_peer(), do: GenServer.call(__MODULE__, :register_peer)

  def init(opts) do
    state = %{
      modules: opts.modules,
      config: Bitcoin.Node.config(),
      peers: []
    }

    {:ok, _pid} = Reagent.start_link(Bitcoin.Node.Network.Peer, port: state.config[:listen_port])
    self() |> send(:periodical_connectivity_check)

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
    Lager.info("[CM] #{num_conn} peers connected")

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
    Lager.info("[CM] unregistered peer #{peer |> inspect}")
    self() |> send(:check_connectivity)
    {:noreply, state |> Map.put(:peers, state.peers |> List.delete(peer))}
  end

  def handle_call(:register_peer, {peer, _ref}, state) do
    Lager.info("[CM] registered peer #{peer |> inspect}")
    state = state |> Map.put(:peers, [peer | state.peers])
    Process.monitor(peer)
    {:reply, :ok, state}
  end

  def handle_cast({:connect, ip, port}, state) do
    Bitcoin.Node.Network.Peer.start(ip, port)
    {:noreply, state}
  end

  def add_peer(%{modules: modules}) do
    case modules[:addr].get do
      %NetworkAddress{address: ip, port: port} ->
        connect(ip, port)
      nil ->
        Bitcoin.Node.Network.find_more_addrs()
    end
  end

end
