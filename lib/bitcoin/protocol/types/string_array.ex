defmodule Bitcoin.Protocol.Types.StringArray do

  alias Bitcoin.Protocol.Types.VarString

  import Bitcoin.Protocol

  @spec parse_stream(binary) :: {list, binary}
  def parse_stream(payload), do: payload |> collect_items(&VarString.parse_stream/1)

end
