defmodule Bitcoin.Models.Peer do

  defstruct ip_address: {0, 0, 0, 0} # IPV4 or IPV6

  @type t :: %Bitcoin.Models.Peer{
    ip_address: tuple
  }

end