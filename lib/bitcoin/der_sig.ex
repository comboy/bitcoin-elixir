defmodule Bitcoin.DERSig do

  @moduledoc """
  DER Signature.

  DER encoded signatures are used in Bitcoin scripts (with sighash byte at the end).

  This module provides parsing, serialization, normalization and checking if
  the signature meets BIP66 requirements.

  We need to normalize signatures before passing them to erlang's :crypto.verify
  because it will return false if R or S are zero padded (while libsecp256k1 returns true).

  DER Signature format:

  `<<type, total_length, 0x02, r_length, r :: binary, 0x02, s_length, s :: binary>>`

  Plus sighash byte at the end for the signatures present in the script, but this module
  deals with signatures that already have the sighash byte stripped.
  """

  use Bitwise

  defstruct [:length, :r, :s, :type]

  @type t :: %__MODULE__{}

  @doc """
  Parse binary signature into %DERSig{} struct.
  """
  @spec parse(binary) :: t
  def parse(sig) do
    <<type, total_length, sig :: binary>> = sig

    <<0x02, r_length, sig :: binary>> = sig
    <<r :: binary-size(r_length), sig :: binary>> = sig

    <<0x02, s_length, sig :: binary>> = sig
    <<s :: binary-size(s_length)>> = sig

    %__MODULE__{
      length: total_length,
      type: type,
      r: r,
      s: s
    }
  end

  @doc """
  Serialize signature struct into binary.

  `length` from the struct is used in serialization, even if it's incorrect.
  """
  @spec serialize(t) :: binary
  def serialize(%__MODULE__{} = sig) do
    <<sig.type, sig.length, 0x02, byte_size(sig.r), sig.r :: binary, 0x02, byte_size(sig.s), sig.s :: binary>>
  end

  @doc """
  Normalize DER signature.

  Which in our case means only removing leading null bytes from R and S
  and fixing the total_length if it's incorrect.
  """
  @spec normalize(t | binary) :: t | binary
  def normalize(sig)

  def normalize(sig) when is_binary(sig) do
    sig
    |> parse
    |> normalize
    |> serialize
  end

  def normalize(%__MODULE__{} = sig) do
    r = trim(sig.r)
    s = trim(sig.s)
    sig
    |> Map.put(:r, r)
    |> Map.put(:s, s)
    |> Map.put(:length, byte_size(r) + byte_size(s) + 4)
  end

  # Trim leading null bytes
  # But we need to be careful because if the null byte is followed by a byte with 0x80 bit set,
  # removing the null byte would change the number sign.
  defp trim(<<0, b, _bin :: binary>> = sig) when (b &&& 0x80) == 0x80, do: sig
  defp trim(<<0, bin :: binary>>), do: trim(bin)
  defp trim(bin), do: bin

  #TODO def strict?(sig) https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki
end
