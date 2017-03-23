defmodule Bitcoin.Node.Peers.ConnectionPool do
  use Reagent

  def start(connection) do
    GenServer.start(__MODULE__, connection, name: __MODULE__)
  end

  use GenServer

  def init(connection) do
    {:ok, connection}
  end

  require Lager

  def add_peer(peer) do
    Lager.info "Peer connection pool received request to add peer: #{inspect(peer)}"
  end

  # Server

  # this message is sent when the socket has been completely accepted and the
  # process has been made owner of the socket, you don't need to wait for it
  # when implementing handle because it's internally handled
  def handle_info({ Reagent, :ack }, connection) do
    Lager.info "New Peer Connection"
    connection |> Socket.active!()
    { :noreply, connection }
  end

  def handle_info({ :tcp, _, data }, connection) do
    connection |> Socket.Stream.send!(data)
    { :noreply, connection }
  end

  def handle_info({ :tcp_closed, _ }, connection) do
    Lager.info "Closed Peer Connection"
    { :stop, :normal, connection }
  end

end