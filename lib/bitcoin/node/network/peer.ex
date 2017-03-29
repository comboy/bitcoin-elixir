defmodule Bitcoin.Node.Network.Peer do
  @moduledoc """
    Connection handler. Manages peer state, sends mesasges, responds to pings etc.

    TODO maybe we should consider splitting connection and peer to separate genservers.
    This will double number of processes, but it shouldn't be a problem below a few hundred
    thousad peers. The problem is that API for accessing it from the outside may be a bit
    more complicated (connection should be a master to peer, but we probably rather want to
    call higher level functions on peer)

    FIXME abstraction mixup, ConnectionManager uses Reagent with this module as a handler,
    but we want both ConnectionManager and Peer to be swapped independently, so ConnectionManager
    must implemetn it's own Reagent handler that talks to the Peer module

    TODO close connection if there's no successful handshake within specific time
  """

  use GenServer
  use Reagent
  require Lager

  alias Bitcoin.Node
  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types.NetworkAddress

  @ping_timeout 30_000 # 30 seconds
  @ping_frequency 600_000 # 10 minutes

  # Initialize Peer asking it to make  connection to specific
  def start(%Reagent.Connection{} = conn), do: GenServer.start(__MODULE__, conn)
  def start(ip, port \\ 8333), do: GenServer.start(__MODULE__, %{ip: ip, port: port})


  #
  # Init
  #

  # Initialziation with ip and port, i.e. try to connect to specified addr
  def init(%{ip: ip, port: port}) do
    state = %{
      ip: ip,
      port: port,
      status: :connecting,
      direction: :out,
      buffer: ""
    }

    # Connect may take a long time, we want init to finish as fast as possible
    self() |> send(:connect)

    {:ok, state}
  end

  # Reagent initalization, called by reagent on accepted socket
  def init(%Reagent.Connection{socket: socket}) do
    {:ok, {ip, port}} = :inet.peername(socket)

    state = %{
      ip: ip,
      port: port,
      direction: :in,
      status: :connecting,
      socket: socket,
      buffer: ""
    }

    {:ok, state}
  end

  def handle_info({ Reagent, :ack }, state) do
    state.socket |> Socket.active!()
    self() |> send(:handshake)
    {:noreply, state}
  end

  #
  # Internal messages
  #

  # Initialize TCP connection
  def handle_info(:connect, %{ip: ip, port: port} = state) do
    Lager.info "Connecting to #{ip |> :inet.ntoa}:#{port}"
    case :gen_tcp.connect(ip, port, [:binary, active: true]) do
      # Successful connection
      {:ok, socket} ->
        self() |> send(:handshake)
        {:noreply, state |> Map.put(:socket, socket)}
      # Timout while trying to connect
      {:error, :etimedout} ->
        state |> disconnect(:connection_timeout)
      # Connection error
      {:error, _} ->
        state |> disconnect(:connection_error)
    end
  end

  # Initialize handshake by sending the VERSION packet
  def handle_info(:handshake, state) do
    node_config = Node.config()

    pkt = %Messages.Version{
      address_of_receiving_node: %NetworkAddress{
        address: state.ip |> ip_to_inet,
        port: state.port,
        },
      address_of_sending_node: %NetworkAddress{
        address: node_config.listen_ip |> ip_to_inet,
        port: node_config.listen_port,
        services: node_config.services,
        },
    }
      |> Map.merge(Bitcoin.Node.version_fields())
      |> Bitcoin.Protocol.Message.serialize

    :ok = state.socket |> :gen_tcp.send(pkt)
    {:noreply, state}
  end

  # Periodically send PING and ensure PONG is received
  def handle_info(:periodic_ping, state) do
    nonce = Bitcoin.Util.nonce64()
    %Messages.Ping{nonce: nonce} |> send_message(state)

    state = state
      |> Map.put(:last_ping_nonce, nonce)
      |> Map.put(:last_ping_time, Bitcoin.Util.militime())

    self() |> Process.send_after(:check_ping_response, @ping_timeout)
    self() |> Process.send_after(:periodic_ping, @ping_frequency)

    {:noreply, state}
  end

  # Check if we got an answer to our ping message
  # We set last_ping_nonce to 0 when PONG with the proper nonce is received,
  # so if it is set to zero, it means everything is ok
  def handle_info(:check_ping_response, %{last_ping_nonce: 0} = state), do: {:noreply, state}
  # last_ping_nonce != 0 which means we did not receive the PONG
  def handle_info(:check_ping_response, state), do: state |> disconnect(:ping_timout)

  #
  # Message handlers
  #

  def handle_info({:msg, %Messages.Verack{}}, state) do
    # We consider connection to be established when we receive VERSION packet and validate it,
    # so we don't really care about the VERACK
    {:noreply, state}
  end

  def handle_info({:msg, %Messages.Version{} = version}, state) do
    state |> debug("=> VERSION #{version |> inspect}")

    case validate_version(version) do
      :ok ->
        %Messages.Verack{} |> send_message(state)
        {:noreply, state |> Map.put(:version, version) |> handle_connected}
      _  ->
        state |> disconnect(:version_mismatch)
    end
  end

  def handle_info({:msg, %Messages.Ping{nonce: nonce}}, state) do
    state |> debug("=> PING")
    %Messages.Pong{nonce: nonce} |> send_message(state)
    {:noreply, state}
  end

  def handle_info({:msg, %Messages.Pong{nonce: nonce}}, state) do
    state |> debug("=> PONG")

    state = cond do
      nonce == state[:last_ping_nonce] ->
        state
          |> Map.put(:ping_latency, Bitcoin.Util.militime() - state[:last_ping_time])
          |> Map.put(:last_ping_nonce, 0)
      true -> state
    end

    {:noreply, state}
  end

  def handle_info({:msg, %Messages.GetHeaders{} = _msg}, state) do
    state |> debug("=> GET HEADERS")
    {:noreply, state}
  end

  def handle_info({:msg, %Messages.Inv{inventory_vectors: inventory_vectors} = _msg}, state) do
    state |> debug("=> INV  #{inventory_vectors |> inspect}")
    #Lager.info "#{ip |> inspect} <= I WANT IT ALL "
    #%Messages.GetData{
      #inventory_vectors: inventory_vectors |> Enum.filter(fn iv -> iv.reference_type == :msg_tx end)
    #}|> send_message(state)
    {:noreply, state}
  end

  def handle_info({:msg, msg}, state) do
    state |> debug("=>? #{msg |> inspect}")
    {:noreply, state}
  end

  #
  # TCP stuff
  #

  def handle_info({:tcp, _port, data}, state) do
    #state |> debug(">> #{data |> Base.encode16}")
    state = state |> Map.put(:buffer, process_buffer(state[:buffer] <> data))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    state
      |> debug("connection closed")
      |> disconnect(:tcp_closed)
  end


  def process_buffer(buffer) when byte_size(buffer) < 24, do: buffer # 24 is the header size
  def process_buffer(buffer) do
    [msg, remaining] = buffer |> Bitcoin.Protocol.Message.parse_stream
    case msg do
      nil -> remaining
      _   ->
        self() |> send({:msg, msg.payload.message})
        remaining |> process_buffer
    end
  end

  def send_message(msg, state) do
    data = msg |> Bitcoin.Protocol.Message.serialize
    state.socket |> :gen_tcp.send(data)
    :ok
  end

  # Convert provided ip address to the ip tuple
  def ip_to_inet({_,_,_,_} = inet), do: inet # IPv4
  def ip_to_inet({_,_,_,_,_,_,_,_} = inet), do: inet # IPv6
  def ip_to_inet(ip), do: ({:ok, _inet} = ip |> :inet.parse_address) |> elem(1)


  # Called after a successful handshake.
  defp handle_connected(state) do
    :ok = Node.Network.modules()[:connection_manager].register_peer()
    self() |> send(:periodic_ping)
    state
      |> Map.put(:status, :connected)
      |> debug("successfully connected")
  end

  defp debug(%{ip: ip, port: port, direction: direction} = state, msg) do
    Lager.debug "[#{direction}] #{ip |> :inet.ntoa}:#{port} #{msg}"
    state
  end

  defp disconnect(state, reason \\ :none) do
    Lager.info "#{state.ip |> :inet.ntoa} disconnected :#{reason}"
    {:stop, :normal, state |> Map.put(:status, :disconnected)}
  end

  defp validate_version(%Messages.Version{} = version) do
    cond do
      version.nonce == Bitcoin.Node.nonce() ->
        {:error, :self_connection}
      true ->
        :ok
    end
  end

end



