defmodule Bitcoin.Node.Network.Discovery do
  require Logger
  use GenServer

  alias Bitcoin.Protocol.Types.NetworkAddress

  defmodule Strategy.DNS do
    @moduledoc """
      Implements DNS node discovery.

      from Satoshi C Client (chainparams.cpp):
      * alexykot.me
      * bitcoin.petertodd.org
      * bluematt.me
      * bitcoin.schildbach.de

      https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery#DNS_Addresses
    """

    require Logger

    @domains [
      [ "bitcoin.sipa.be", 'seed.bitcoin.sipa.be' ], # Pieter Wuille
      [ "bluematt.me", 'dnsseed.bluematt.me' ], # Matt Corallo
      [ "dashjr.org", 'dnsseed.bitcoin.dashjr.org' ], # Luke Dashjr
      [ "bitcoinstats.com", 'seed.bitcoinstats.com' ], # Christian Decker
      [ "xf2.org", 'bitseed.xf2.org' ], # Jeff Garzik
      [ "bitcoin.jonasschnelli.ch", 'seed.bitcoin.jonasschnelli.ch' ] # Jonas Schnelli
    ]

    def gather_peers(%{modules: modules} = _opts) do

      Enum.map(@domains, fn([seed_name, domain]) -> 
        Logger.info("Starting Peer Discovery via DNS for seed #{seed_name} at domain #{domain}")
        Enum.each(:inet_res.lookup(domain, :in, :a), fn(ip) ->
          %NetworkAddress{
            address: ip, 
            time: Bitcoin.Node.timestamp()
          } |> modules[:addr].add
        end)
      end)

    end

  end

  def start_link(%{modules: _modules} = opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # Public Interface
  def begin_discovery, do: GenServer.cast(__MODULE__, :begin_discovery)

  def handle_cast(:begin_discovery, %{discovery_started: true} = opts), do: {:noreply, opts}
  def handle_cast(:begin_discovery, opts) do
    Logger.info "Beginning Peer Discovery Process"
    Strategy.DNS.gather_peers(opts)
    {:noreply, opts |> Map.put(:discovery_started, true)}
  end

end
