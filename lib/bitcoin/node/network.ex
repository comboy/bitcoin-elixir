defmodule Bitcoin.Node.Network do

  # TODO 
  # def connected?
  # def connections
  # def connect (this should be called on node start if node is started with some addnode option)
  # some kind of health indicator?
  #
  # This module is also probably where Node will be requesting to fetch misisng inv / headers etc.

  alias Bitcoin.Node.Network

  @default_modules [
    # Addrs managager, keeps list of IPs to connect to
    addr: Network.Addr,
    # Peer connection handler, exchanges information with a single peer
    peer: Network.Peer,
    # Peers discovery - find IPs of peers to connect to if we have non in the database
    discovery: Network.Discovery,
    # Connection manager, accepts incoming connection, keeps track of all connected peers
    connection_manager: Network.ConnectionManager
  ]


  def find_more_addrs do
    modules[:discovery].begin_discovery()
  end

  def modules do
    case Application.get_env(:bitcoin, :node, :modules) do
       nil -> @default_modules
      list -> @default_modules |> Keyword.merge(list)
    end
  end

end
