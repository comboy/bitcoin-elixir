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

  Currently still more script/tx tests are passing with libsecp256k1 than with the na(t)ive implementation.
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
end
