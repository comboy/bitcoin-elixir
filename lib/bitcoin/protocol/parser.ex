defmodule Bitcoin.Protocol.Parser do
  alias Bitcoin.Protocol.Types.Integer

  # Common pattern in protocol messages is var_int followed by a structure repeated number of times
  # This function parses it and returns [collection_of_items, remaining_payload]
  # Aruments are payload and module associated with the parsed structure
  def collect_items(payload, module) do
    [count, payload] = payload |> Integer.parse_stream
    collect_items(payload, module, count, [])
  end

  def collect_items(payload, module, 0, items), do: [items |> Enum.reverse, payload]
 
  def collect_items(payload, module, count, items) do
    [item, payload] = payload |> module.parse_stream
    collect_items(payload, module, count - 1, [item | items])
  end

end
