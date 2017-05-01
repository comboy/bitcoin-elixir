ExUnit.start()
ExUnit.configure(exclude: [dummy_data: true])

defmodule Test.Helper do
  def flags_string_to_map(flags) do
    %{
      "P2SH" => :p2sh,
      "DERSIG" => :dersig,
      "LOW_S" => :low_s,
      "STRICTENC" => :strictenc
    } |> Enum.reduce(%{}, fn({str, sym}, map) ->
      cond do
        flags |> String.contains?(str) -> map |> Map.put(sym, true)
        true -> map
      end
    end)
  end
end
