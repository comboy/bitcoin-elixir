defmodule Bitcoin.Node.Peers.Discovery do
  require Lager
  use GenServer

  alias Bitcoin.Models.Peer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {:ok, opts}, opts)
  end

  def init({:ok, opts}) do
    # begin_discovery(opts[:peer_connection_pool])
    { :ok, opts }
  end

  @moduledoc """
    Implements DNS node discovery.

    from Satoshi C Client (chainparams.cpp):
    * alexykot.me
    * bitcoin.petertodd.org
    * bluematt.me
    * bitcoin.schildbach.de

    https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery#DNS_Addresses
  """
  defmodule Strategy.DNS do

    require Lager

    @domains [
      [ "bitcoin.sipa.be", 'seed.bitcoin.sipa.be' ], # Pieter Wuille
      [ "bluematt.me", 'dnsseed.bluematt.me' ], # Matt Corallo
      [ "dashjr.org", 'dnsseed.bitcoin.dashjr.org' ], # Luke Dashjr
      [ "bitcoinstats.com", 'seed.bitcoinstats.com' ], # Christian Decker
      [ "xf2.org", 'bitseed.xf2.org' ], # Jeff Garzik
      [ "bitcoin.jonasschnelli.ch", 'seed.bitcoin.jonasschnelli.ch' ] # Jonas Schnelli
    ]

    def gather_peers(peer_pool) do

      Enum.map(@domains, fn([seed_name, domain]) ->
        Lager.info("Starting Peer Discovery via DNS for seed #{seed_name} at domain #{domain}")
        Enum.each(:inet_res.lookup(domain, :in, :a), fn(peer) ->
          peer_pool.add_peer(%Peer{ip_address: peer})
        end)
      end)

    end

  end

  # Public Interface
  def begin_discovery(peer_connection_pool) do
    GenServer.cast(__MODULE__, {:begin_discovery, peer_connection_pool})
  end

  def handle_cast({:begin_discovery, peer_connection_pool}, state) do
    Lager.info "Beginning Peer Discovery Process"
    Strategy.DNS.gather_peers(peer_connection_pool)
    {:noreply, state}
  end

end