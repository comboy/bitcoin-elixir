ExUnit.start()
ExUnit.configure(exclude: [dummy_data: true])

defmodule Test.Helper do

  # "P2SH,STRICTENC" => %{p2sh: true, :strictenc: true}
  def flags_string_to_map(flags) do
    flags
    |> String.split(",")
    |> Enum.map(fn name -> name |> String.trim |> String.downcase |> String.to_atom end)
    |> Enum.reduce(%{}, fn(flag, acc) -> acc |> Map.put(flag, true) end)
  end
end
