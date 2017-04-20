defmodule Bitcoin.Node.Network.Discovery do

  use Bitcoin.Common
  use GenServer

  require Logger

  alias Bitcoin.Protocol.Types.NetworkAddress

  defmodule Strategy.DNS do
    @moduledoc """
      DNS node discovery.

      https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery#DNS_Addresses
    """

    use Bitcoin.Common

    require Logger

    def gather_peers(_opts) do
      @dns_seeds
      |> Enum.each(fn {seed_name, domain} ->
        Logger.info("Starting Peer Discovery via DNS for seed #{seed_name} at domain #{domain}")

        :inet_res.lookup(domain, :in, :a)
        |> Enum.map(fn ip ->
          %NetworkAddress{
            address: ip,
            port: @default_listen_port,
            time: Bitcoin.Node.timestamp()
          }
        end)
        |> Enum.each(fn addr -> @modules[:addr].add(addr) end)

      end)
      :ok
    end

  end

  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # Public Interface
  def begin_discovery, do: GenServer.cast(__MODULE__, :begin_discovery)

  def handle_cast(:begin_discovery, %{discovery_started: true} = opts), do: {:noreply, opts}
  def handle_cast(:begin_discovery, opts) do
    Logger.info "Beginning Peer Discovery Process"
    Strategy.DNS.gather_peers(opts)
    {:noreply, opts |> Map.put(:discovery_started, true)}
  end

end
