defmodule Bitcoin.Common do

   # We do everything with __using__ macro so that we can use constants later in code
   # as something that is known at compilation time (e.g. in guards)

  defmacro __using__(_opts) do
    quote do
      use Bitcoin.Const

      ## CONFIGURABLE MODULES

      @modules [
        # Addrs managager, keeps list of IPs to connect to
        addr: Bitcoin.Node.Network.Addr,
        # Peer connection handler, exchanges information with a single peer
        peer: Bitcoin.Node.Network.Peer,
        # Peers discovery - find IPs of peers to connect to if we have non in the database
        discovery: Bitcoin.Node.Network.Discovery,
        # Connection manager, accepts incoming connection, keeps track of all connected peers
        connection_manager: Bitcoin.Node.Network.ConnectionManager,
        # Inventory manager - fetching missing inventory, sending new inv to storage and blockchain sync
        inventory: Bitcoin.Node.Inventory,
        # Storage engine - persistance layer
        storage_engine: Bitcoin.Node.Storage.Engine.Dummy
      ]

      # Overwrite with modules defined in config
      @modules (case Application.get_env(:bitcoin, :node, [])[:modules] do
         nil -> @modules
        list -> @modules |> Keyword.merge(list)
      end)

    end
  end
end
