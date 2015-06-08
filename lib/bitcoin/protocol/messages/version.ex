defmodule Bitcoin.Protocol.Messages.Version do

  @moduledoc """
    When a node creates an outgoing connection, it will immediately advertise its version.
    The remote node will respond with its version.
    No further communication is possible until both peers have exchanged their version.

    https://en.bitcoin.it/wiki/Protocol_documentation#version
  """

  alias Bitcoin.Protocol.Types.String
  alias Bitcoin.Protocol.Types.NetworkAddress

  defstruct version: 0, # (int32_t) Identifies protocol version being used by the node
            services: <<1, 0, 0, 0, 0, 0, 0, 0>>, # (uint64_t) bitfield of features to be enabled for this connection
            timestamp: 0, # (int64_t) standard UNIX timestamp in seconds
            address_of_receiving_node: NetworkAddress, # The network address of the node receiving this message. - Bitcoin.Protocol.Types.NetworkAddress
            # versions 106 and greater, otherwise these fields do not exist
            address_of_sending_node: NetworkAddress, # The network address of the node emitting this message. - Bitcoin.Protocol.Types.NetworkAddress
            nonce: 0, # (uint64_t) Node random nonce, randomly generated every time a version packet is sent. This nonce is used to detect connections to self.
            user_agent: "", # User Agent (0x00 if string is 0 bytes long)
            start_height: 0, # (int32_t) The last block received by the emitting node
            relay: false # (bool) Whether the remote peer should announce relayed transactions or not, may be absent, see BIP 0037 <https://github.com/bitcoin/bips/blob/master/bip-0037.mediawiki>, since version >= 70001

  @type t :: %Bitcoin.Protocol.Messages.Version{
    version: non_neg_integer,
    services: bitstring,
    timestamp: non_neg_integer,
    address_of_receiving_node: binary,
    address_of_sending_node: binary,
    nonce: non_neg_integer,
    user_agent: String.t,
    start_height: non_neg_integer,
    relay: boolean
  }

  def parse(data) do

    <<version :: unsigned-little-integer-size(32),
      services :: bitstring-size(64),
      timestamp :: unsigned-little-integer-size(64),
      remaining :: binary
    >> = data

    [address_of_receiving_node, remaining] = NetworkAddress.parse_version_stream(remaining)
    [address_of_sending_node, remaining] = NetworkAddress.parse_version_stream(remaining)

    <<nonce :: unsigned-little-integer-size(64),
      remaining :: binary
    >> = remaining

    [user_agent, remaining] = String.parse_stream(remaining)

    <<start_height :: unsigned-little-integer-size(32),
      relay :: binary
    >> = remaining

    if relay == <<1>> do # Relay may be absent, see https://github.com/bitcoin/bips/blob/master/bip-0037.mediawiki
      relay = true
    else
      relay = false
    end

    %Bitcoin.Protocol.Messages.Version{
      version: version,
      services: services,
      timestamp: timestamp,
      address_of_receiving_node: address_of_receiving_node,
      address_of_sending_node: address_of_sending_node,
      nonce: nonce,
      user_agent: user_agent,
      start_height: start_height,
      relay: relay
    }

  end

end