defmodule Bitcoin.Secp256k1 do

  @moduledoc """
  ECDSA Secp256k1 curve operations.

  We are currentnly using :crypto.verify (openssl), which behaviour does not seem to match
  bitcoin-core/libsecp256k1.

  We could switch to NIF but keeping native imlpmentation has its advantages:
  * NIFs bring some mess, gcc must present, make is different on different platforms,
    libsecp256k1 configure may fail, i.e. there's a lot of things that can go wrong when
    somebody is trying to run the project or use it as a lib.
  * One of the points of the whole project is to learn more about Bitcoin, trying to recreate
    libsecp256k1 behaviour may be an interesting lesson
  * Error in NIF (error in the library is much less likely) would bring the whole VM down
    (not just the running process)

  That said, NIF would bring a lot of speedup and it's better consensus-wise.

  I haven't yet prepared a proper lib, if you want to compare libsecp256k1 behaviour,
  check out this gist: https://gist.github.com/comboy/018e15c574d44b2bbc0992d4e42a119d
  """

  alias Bitcoin.DERSig

  @doc """
  Verify signed message.

  Returns `true` if the signature matches public key.

  `msg` should already be a 32 byte long digest.
  """
  @spec verify(binary, binary, binary) :: boolean
  def verify(msg, sig, pk) do
    :crypto.verify(:ecdsa, :sha256, {:digest, msg}, sig |> DERSig.normalize, [pk, :secp256k1])
  end

  @doc """
  Secp256k1 parameters.

  http://www.secg.org/sec2-v2.pdf
  """
  @spec params :: map
  def params do
    %{
      p: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_FFFFFC2F,
      a: 0x00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
      b: 0x00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000007,
      G: 0x04_79BE667E_F9DCBBAC_55A06295_CE870B07_029BFCDB_2DCE28D9_59F2815B_16F81798_483ADA77_26A3C465_5DA4FBFC_0E1108A8_FD17B448_A6855419_9C47D08F_FB10D4B8,
      n: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141,
      h: 0x01
    }
  end
end
