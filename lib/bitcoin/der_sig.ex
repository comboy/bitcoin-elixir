defmodule Bitcoin.DERSig do

  @moduledoc """
  DER Signature.

  DER encoded signatures are used in Bitcoin scripts (with sighash byte at the end).

  This module provides parsing, serialization, normalization and checking if
  the signature meets BIP66 requirements.

  We need to normalize signatures before passing them to erlang's :crypto.verify
  because it will return false if R or S are zero padded (while libsecp256k1 returns true).

  DER Signature format:

  `<<type, total_length, r_type, r_length, r :: binary, s_type, s_length, s :: binary>>`

  Plus sighash byte at the end for the signatures present in the script, but this module
  deals with signatures that already have the sighash byte stripped.

  In strict DER signature `type` should be `0x30` (compound), and `r_encoding` and `s_encoding` should
  equal `0x02` (integer).

  ## Links:

  * https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki
  * https://en.wikipedia.org/wiki/X.690
  * https://www.itu.int/rec/T-REC-X.690/en
  """

  use Bitwise

  alias Bitcoin.Secp256k1

  defstruct [:length, :r_type, :r, :s_type, :s, :type]

  @type t :: %__MODULE__{}

  # Upper bound for what's considered a low S value, inclusive (see BIP62)
  @low_s_max Secp256k1.params[:n] / 2

  @doc """
  Parse binary signature into %DERSig{} struct.
  """
  @spec parse(binary) :: t
  def parse(sig) do
    struct(__MODULE__, parse_raw(sig))
  end

  @doc """
  Serialize signature struct into binary.

  `length` from the struct is used in serialization, even if it's incorrect.
  """
  @spec serialize(t) :: binary
  def serialize(%__MODULE__{} = der) do
    <<der.type, der.length, der.r_type, byte_size(der.r), der.r :: binary, der.s_type, byte_size(der.s), der.s :: binary>>
  end

  @doc """
  Normalize DER signature.

  * remove leading null bytes from R and S
  * fix total_length if it's incorrect
  * fix negative S
  * fix negative R
  * ensure low S
  """
  @spec normalize(t | binary) :: t | binary
  def normalize(sig)

  def normalize(sig) when is_binary(sig) do
    sig
    |> parse
    |> normalize
    |> serialize
  end

  def normalize(%__MODULE__{} = der) do
    r = der.r |> trim |> fix_negative
    s = der.s |> trim |> low_s |> fix_negative
    der
    |> Map.put(:r, r)
    |> Map.put(:s, s)
    |> Map.put(:length, byte_size(r) + byte_size(s) + 4)
  end

  @doc """
  Returns false when S > order/2

  See https://github.com/bitcoin/bips/blob/master/bip-0062.mediawiki#Low_S_values_in_signatures for details.
  """
  @spec low_s?(t | binary) :: boolean
  def low_s?(sig)
  def low_s?(sig) when is_binary(sig), do: sig |> parse |> low_s?
  def low_s?(der), do: der.s <= @low_s_max

  @doc """
  Check if the signature is a strict DER signature (BIP66)

  Note that we operate on sig that already has the sighash byte stripped.
  """
  @spec strict?(binary) :: boolean
  def strict?(sig) when is_binary(sig) do
    der = parse_raw(sig)
    cond do
      # Minimum size constraint
      byte_size(sig) < 8
        -> false

      # Maximum size constraint
      byte_size(sig) > 72
        -> false

      # A signature is of type 0x30 (compound).
      der.type != 0x30
        -> false

      # Length covers the entire signature
      der.length != byte_size(sig) - 2
        -> false

      # Make sure the length of the S element is still inside the signature
      # -> Our parser will currently raise if it's not

      # Length of the signature matches the sum of the length of the elements
      der.length != der.r_length + der.s_length + 4
        -> false

      # R element is an integer.
      der.r_type != 0x02
        -> false

      # R length > 0
      der.r == <<>>
        -> false

      # R is positive
      (Binary.at(sig, 4) &&& 0x80) == 0x80
        -> false

      # No unecessary null bytes at the start of R
      trim(der.r) != der.r
        -> false

      # Check whether the S element is an integer.
      der.s_type != 0x02
        -> false

      # S length > 0
      der.s == <<>>
        -> false

      # S is not negative
      (Binary.at(der.s, 0) &&& 0x80) == 0x80
        -> false

      # No unecessary null bytes at the start of S
      trim(der.s) != der.s
        -> false

      # All passed
      true -> true
    end
  end

  # Parses signature
  defp parse_raw(sig) do
    <<type, total_length, sig :: binary>> = sig

    <<r_type, r_length, sig :: binary>> = sig
    <<r :: binary-size(r_length), sig :: binary>> = sig

    <<s_type, s_length, sig :: binary>> = sig
    <<s :: binary-size(s_length), _bin :: binary>> = sig

    %{
      length: total_length,
      type: type,
      r_type: r_type,
      r_length: r_length,
      r: r,
      s_type: s_type,
      s_length: s_length,
      s: s
    }
  end

  # Trim leading null bytes
  # But we need to be careful because if the null byte is followed by a byte with 0x80 bit set,
  # removing the null byte would change the number sign.
  defp trim(<<0, b, _bin :: binary>> = sig) when (b &&& 0x80) == 0x80, do: sig
  defp trim(<<0, bin :: binary>>), do: trim(bin)
  defp trim(bin), do: bin

  # Ensure that the low S value is used
  defp low_s(s) when s > @low_s_max, do: (Secp256k1.params[:n] - Binary.to_integer(s)) |> Binary.from_integer
  defp low_s(s), do: s

  # S should not be negative. But you can find it negative e.g in tx 70f7c15c6f62139cc41afa858894650344eda9975b46656d893ee59df8914a3d
  # You can also find negative R in tx 251d9cc59d1fc23b0ec6e62aff6106f1890bf9ed4eb0b7df70319d3e555f4fd2
  # These are encoding errors, null byte must be appendend at the beginning so that these numbers are interpreted as positive
  defp fix_negative(<<b, _ :: binary>> = bin) when (b &&& 0x80) == 0x80, do: <<0, bin :: binary>>
  defp fix_negative(bin), do: bin

end
