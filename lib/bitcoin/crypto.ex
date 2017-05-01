defmodule Bitcoin.Crypto do
  @moduledoc """
  Currently just wrappers around erlang's :crypto for easy piping.
  """

  def ripemd160(bin), do: :crypto.hash(:ripemd160, bin)
  def sha1(bin), do: :crypto.hash(:sha, bin)
  def sha256(bin), do: :crypto.hash(:sha256, bin)

end
