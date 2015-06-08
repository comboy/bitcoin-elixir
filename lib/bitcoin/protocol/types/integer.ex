defmodule Bitcoin.Protocol.Types.Integer do

  def parse(<<0xFD, data :: unsigned-little-integer-size(16)>>) do
    data
  end

  def parse(<<0xFE, data :: unsigned-little-integer-size(32)>>) do
    data
  end

  def parse(<<0xFF, data :: unsigned-native-integer-size(64)>>) do
    data
  end

  def parse(<<data :: unsigned-integer-size(8)>>) do
    data
  end

  def parse_stream(<<0xFD, data :: unsigned-little-integer-size(16), remaining :: binary>>) do
    [data, remaining]
  end

  def parse_stream(<<0xFE, data :: unsigned-little-integer-size(32), remaining :: binary>>) do
    [data, remaining]
  end

  def parse_stream(<<0xFF, data :: unsigned-native-integer-size(64), remaining :: binary>>) do
    [data, remaining]
  end

  def parse_stream(<<data :: unsigned-integer-size(8), remaining :: binary>>) do
    [data, remaining]
  end

end