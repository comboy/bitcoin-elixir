defmodule Bitcoin.Node.Network do

  use Bitcoin.Common

  # Check if we are connected to the network.
  # Checks if connection manager is already running and then checks number of  connected peers
  def connected?, do: GenServer.whereis(@modules[:connection_manager]) && length(@modules[:connection_manager].peers) > 0

  # Called by connection manager if there's not enough known addresses to connect to 
  def find_more_addrs, do: @modules[:discovery].begin_discovery()

end
