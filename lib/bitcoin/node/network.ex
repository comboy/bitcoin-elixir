defmodule Bitcoin.Node.Network do

  # TODO 
  # def connected?
  # def connections
  # def connect (this should be called on node start if node is started with some addnode option)
  # some kind of health indicator?
  #
  # This module is also probably where Node will be requesting to fetch misisng inv / headers etc.

  def find_more_addrs do
    modules[:discovery].begin_discovery()
  end

  # TODO use config
  def modules do
    [
      addr: Bitcoin.Node.Network.Addr,
      discovery: Bitcoin.Node.Network.Discovery,
      connection_manager: Bitcoin.Node.Network.ConnectionManager
    ]
  end

end
