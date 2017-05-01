defmodule Bitcoin.Script.P2SH do

  @moduledoc """
  Handler for Pay to Script Hash scripts.

  More info can be faund in the BIP: https://github.com/bitcoin/bips/blob/master/bip-0016.mediawiki
  """

  alias Bitcoin.Script
  alias Bitcoin.Crypto

  defmacro __using__(_opts) do
    quote do

      # Match Pay to script hash pattern
      # https://github.com/bitcoin/bips/blob/master/bip-0016.mediawiki
      # TODO we should have some run_sig_pk or another way to get more specific errors
      def verify_sig_pk([serialized_script | sig_script], [:OP_HASH160, << hash :: binary-size(20) >>, :OP_EQUAL], %{flags: %{p2sh: true}} = opts) when is_binary(serialized_script) and sig_script != [] do
        cond do
          # Only push data allowed
          sig_script |> Enum.any?(& is_atom(&1) && !(&1 in @push_data_ops)) ->
            false # {:error, :onlp_pushdata_in_p2sh_sig}
          # Hash must still match
          serialized_script |> Crypto.sha256 |> Crypto.ripemd160 == hash ->
            verify_sig_pk(sig_script, serialized_script |> Script.parse, opts)
          # If hash doesn't match, the script is invalid
          true ->
            false # {:error, :p2sh_hash_invalid}
        end
      end

    end
  end
end
