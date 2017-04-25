defmodule Bitcoin.Base58Check do

  @moduledoc """
  Base58Check encoding.

  Base58Check is used in Bitcoin addresses and WIF.
  It's a Base58 where additional 4 checksum bytes are appended to the payload
  before encoding (and stripped and checked when decoding).

  Checksum is first 4 bytes from the double sha256 of the payload.
  """

  # Base58 alphabet, without 0,O,l,I
  @code '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
  @code_0 @code |> List.first

  # optimization to avoid browsing code list each time, with this we have O(1)
  @num_to_code @code |> Enum.with_index |> Enum.map(fn {k,v} -> {v,k} end) |> Enum.into(%{})
  @code_to_num @code |> Enum.with_index |> Enum.into(%{})

  @doc """
  Encode binary into Base58Check.
  """
  @spec encode(binary) :: String.t
  def encode(payload) do
    payload
    |> Binary.append(payload |> checksum)
    |> base_encode
  end

  @doc """
  Decode Base58Check string into binary.

  Returns `{:ok, binary}` tuple in case of success, otherwise an `{:error, err}` tuple.
  """
  @spec decode(String.t) :: {:ok, binary} | {:error, term}
  def decode(string) do
    case string |> base_decode do
      {:ok, bin} ->
         {payload, checksum} = bin |> Binary.split_at(-4)
         if payload |> checksum == checksum do
           {:ok, payload}
         else
           {:error, :invalid_checksum}
         end
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Just like `decode/1` but raises exception in case of an error.
  """
  @spec decode!(String.t) :: binary
  def decode!(string) do
    {:ok, payload} = string |> decode
    payload
  end

  @doc """
  Returns true if the string is a valid Base58Check encoding.
  """
  @spec valid?(String.t) :: boolean
  def valid?(string) do
    # we need to decode anyway to validate the checksum
    {result, _payload} = string |> decode
    result == :ok
  end

  @doc """
  Encode binary payload in Base58.
  """
  @spec base_encode(binary) :: String.t
  def base_encode(payload)

  # Convert leading zeros separately, because they would be lost in to_integer conversion
  def base_encode(<<0>> <> payload) when byte_size(payload) > 0, do: base_encode(<<0>>) <> base_encode(payload)
  # Handle special case because "" would be interpreted as 0, same as <<0>>
  def base_encode(""), do: ""
  # Actual Base58 encoding
  def base_encode(payload) do
    payload
    |> Binary.to_integer
    |> Integer.digits(58)
    |> Enum.map(& @num_to_code[&1])
    |> Binary.from_list
  end


  @doc """
  Decode Base58 encoded string into binary.

  Returns `{:ok, binary}` if decoding was successful or `{:error, :invalid_character}` if some
  character outside the alphabet was found.
  """
  @spec base_decode(String.t) :: {:ok, binary} | {:error, term}
  def base_decode(string) do
    case base_valid?(string) do
      true  -> {:ok, string |> base_decode!}
      false -> {:error, :invalid_character}
    end
  end

  @doc """
  Same as `base_decode/1` but returns binary without the tuple and raisse exception in case of an error.
  """
  @spec base_decode!(String.t) :: binary
  def base_decode!(string)

  # Append base_decoded zeros separately, otherwise they would be lost in From_integer conversion
  def base_decode!(<<@code_0>> <> string) when byte_size(string) > 0, do: base_decode!(<<@code_0>>) <> base_decode!(string)
  # Handle special case because Integer.undigits([]) == 0
  def base_decode!(""), do: ""
  # Actual Base58 decoding
  def base_decode!(string) do
    string
    |> Binary.to_list
    |> Enum.map(& @code_to_num[&1])
    |> Integer.undigits(58)
    |> Binary.from_integer
  end

  @doc """
  Check if the string is a valid Base58 encoding.
  """
  @spec base_valid?(String.t) :: boolean
  def base_valid?(string)

  def base_valid?(""), do: true
  def base_valid?(<<char>> <> string), do: char in @code && base_valid?(string)


  defp checksum(payload), do: payload |> Bitcoin.Util.double_sha256 |> Binary.take(4)

end
