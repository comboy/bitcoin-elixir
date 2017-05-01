defmodule Bitcoin.Key.Public do

  @doc """
  Check if public key is in either compressed or uncompressed format.

  Used for validation with the STRICTENC flag.
  """
  @spec strict?(binary) :: boolean
  def strict?(pk) do
    cond do
      # Too short
      byte_size(pk) < 33
        -> false

      # Invaild length for uncompressed key
      Binary.at(pk, 0) == 0x04 && byte_size(pk) != 65
        -> false

      # Invalid length for compressed key
      Binary.at(pk, 0) in [0x02, 0x03] && byte_size(pk) != 33
        -> false

      # Non-canonical: neither compressed nor uncompressed
      !(Binary.at(pk, 0) in [0x02, 0x03, 0x04])
        -> false

      # Everything ok
      true -> true
    end
  end

end
