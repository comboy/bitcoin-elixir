defmodule Bitcoin.Script.P2SH do
  defmacro __using__(_opts) do
    quote do

      # Match Pay to script hash pattern
      # https://github.com/bitcoin/bips/blob/master/bip-0016.mediawiki
      # TODO validate that there were no operations other than pushdata in sigscript
      # TODO only match if opts[:flags] include :p2sh
      def run([serialized_script | stack], [:OP_HASH160, << hash :: binary-size(20) >>, :OP_EQUAL], opts) do
        # TODO move to function to share with OP_HASH160
        if :crypto.hash(:ripemd160, :crypto.hash(:sha256, bin(serialized_script))) == hash do
          run(stack, serialized_script |> Bitcoin.Script.Binary.parse, opts)
        else
          :invalid # hash of the serialzed script doesn't watch
        end
      end

    end
  end
end
