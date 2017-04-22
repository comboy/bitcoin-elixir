defmodule Bitcoin.Protocol.Types.IntegerArray do

  import Bitcoin.Protocol

  @spec parse_stream(binary) :: {list(integer), binary}
  def parse_stream(payload) do
    payload |> collect_items(fn payload ->
      << item :: unsigned-little-integer-size(32), payload::binary >> = payload
      {item, payload}
    end)
  end

end
