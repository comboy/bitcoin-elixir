defmodule Bitcoin.Protocol.Types.NetworkAddress do

  defstruct time: 0, # (uint32) the Time (version >= 31402). Not present in version message.
            services: 0, # (uint64_t) bitfield of features to be enabled for this connection. See Version Message.
            address: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, # (char[16]) IPv6 address. Network byte order. The original client only supported IPv4 and only read the last 4 bytes to get the IPv4 address. However, the IPv4 address is written into the message as a 16 byte IPv4-mapped IPv6 address.
            port: 0 # (uint16_t) port number, network byte order

  @type t :: %Bitcoin.Protocol.Types.NetworkAddress{
    time: non_neg_integer,
    services: binary,
    address: non_neg_integer,
    port: non_neg_integer
  }

  def parse(<<time :: unsigned-native-integer-size(32),
              services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16)>>) do
    %Bitcoin.Protocol.Types.NetworkAddress{
      time: time,
      services: services,
      address: address,
      port: port
    }
  end

  def parse_stream(<<time :: unsigned-native-integer-size(32),
                     services :: bitstring-size(64),
                     address :: bytes-size(16),
                     port :: unsigned-big-integer-size(16),
                     remaining_stream :: binary>>) do
    [%Bitcoin.Protocol.Types.NetworkAddress{
      time: time,
      services: services,
      address: address,
      port: port
    }, remaining_stream]
  end

  def parse_version(<<services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16)>>) do
      %Bitcoin.Protocol.Types.NetworkAddress{
        services: services,
        address: address,
        port: port
      }
    end

  def parse_version_stream(<<services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16),
              remaining_stream :: binary>>) do
    [%Bitcoin.Protocol.Types.NetworkAddress{
      services: services,
      address: address,
      port: port
    }, remaining_stream]
  end

end