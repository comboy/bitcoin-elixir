ExUnit.start()

defmodule Test.Helper do
  def flags_string_to_map(flags) do
    %{
      "P2SH" => :p2sh
    } |> Enum.reduce(%{}, fn({str, sym}, map) ->
      cond do
        flags |> String.contains?(str) -> map |> Map.put(sym, true)
        true -> map
      end
    end)
  end
end
