defmodule Bitcoin.Protocol do
  alias Bitcoin.Protocol.Types.VarInteger

  # Common pattern in protocol messages is var_int followed by a structure repeated number of times
  # This function parses it and returns [collection_of_items, remaining_payload]
  # Aruments are payload and a parser. Parser can be a module with the parse_stream function
  # or a function that takes payload and returns [item, remaining_payload]
  def collect_items(payload, :hash) do
    payload |> collect_items(fn payload ->
      <<element :: bytes-size(32), payload :: binary>> = payload
      {element, payload}
    end)
  end

  def collect_items(payload, parser) do
    {count, payload} = payload |> VarInteger.parse_stream
    collect_items(payload, parser, count, [])
  end

  def collect_items(payload, _parser, 0, items), do: {items |> Enum.reverse, payload}

  def collect_items(payload, parser, count, items) when is_atom(parser) do
    {item, payload} = payload |> parser.parse_stream
    collect_items(payload, parser, count - 1, [item | items])
  end

  def collect_items(payload, parser, count, items) when is_function(parser) do
    {item, payload} = payload |> parser.()
    collect_items(payload, parser, count - 1, [item | items])
  end

  # Serialize array of structs into var_int + array format
  def serialize_items(items) do
    VarInteger.serialize(items |> Enum.count)
    <> (
      items
      |> Enum.map(&serialize_item/1)
      |> Enum.reduce(<<>>, &(&2 <> &1))
    )
  end

  defp serialize_item(%{:__struct__ => _} = item), do: (item.__struct__).serialize(item)
  defp serialize_item(item) when is_binary(item), do: item

end
