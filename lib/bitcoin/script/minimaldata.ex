defmodule Bitcoin.Script.Minimaldata do

  @moduledoc """
  Validations for scripts with MINIMALDATA flag enabled

  https://github.com/bitcoin/bips/blob/master/bip-0062.mediawiki#push-operators
  """

  defmacro __using__(_opts) do
    quote do

      # Numbers must use the shortest encoding possible.
      # To enforce that we check if it's the same representation as our Number.bin/1
      # which should use minimal available encoding.
      def num(x, %{flags: %{minimaldata: true}} = _opts) when is_binary(x) do
        value = num(x)
        if x != bin(value) do
          {:error, :minimaldata}
        else
          value
        end
      end

      # Pushing an empty byte sequence must use OP_0.
      def run(stack, [:OP_PUSHDATA1, <<>> | _script],     %{flags: %{minimaldata: true}} = _opts),
        do: {:error, :minimaldata}

      # Pushing a 1-byte sequence of byte 0x01 through 0x10 must use OP_0.
      def run(stack, [:OP_PUSHDATA1, <<byte>> | _script], %{flags: %{minimaldata: true}} = _opts) when byte in 0..10,
        do: {:error, :minimaldata} # TODO script test cases don't cover

      # Pushing the byte 0x81 must use OP_1NEGATE.
      def run(stack, [:OP_PUSHDATA1, <<0x81>> | _script], %{flags: %{minimaldata: true}} = _opts),
        do: {:error, :minimaldata} # TODO script test cases don't cover

      # Pushing any other byte sequence up to 75 bytes must use the normal data push (opcode byte n, with n the number of bytes, followed n bytes of data being pushed).
      def run(stack, [:OP_PUSHDATA1, data | _script],     %{flags: %{minimaldata: true}} = _opts) when byte_size(data) < 75,
        do: {:error, :minimaldata}

      # Pushing 76 to 255 bytes must use OP_PUSHDATA1
      # Pushing 256 to 520 bytes must use OP_PUSHDATA2.
      def run(stack, [:OP_PUSHDATA2, data | _script],     %{flags: %{minimaldata: true}} = _opts) when byte_size(data) < 256,
        do: {:error, :minimaldata}

      # OP_PUSHDATA4 can never be used, as pushes over 520 bytes are not allowed, and those below can be done using other operators.
      def run(stack, [:OP_PUSHDATA4, _data | _script],    %{flags: %{minimaldata: true}} = _opts), 
        do: {:error, :minimaldata}

    end
  end
end
