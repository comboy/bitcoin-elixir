defmodule Bitcoin.Script.Serialization do

  use Bitcoin.Script.Opcodes

  # PUSHDATA with size > @max_element_size makes the script invalid
  @max_element_size 520
  # scripts > 10,000 bytes are invalid
  @max_script_size 10_000

  # Value returned when the script is invalid
  @invalid [:invalid]

  ##
  ## Parsing binary script (as it appears in the transaction)
  ##

  def parse(binary) when is_binary(binary) and byte_size(binary) > @max_script_size, do: @invalid
  def parse(binary) when is_binary(binary) do
    try do
       parse([], binary)
     rescue
       # Match error can occur when there's not enough bytes after pushdata instruction
       _e in MatchError -> @invalid
     end
  end

  # not a binry
  def parse(_), do: @invalid

  def parse(script, <<>>), do: script

  # Opcode 0x01-0x4b: The next opcode bytes is data to be pushed onto the stack
  def parse(script, << size, bin :: binary >>) when size >= 0x01 and size <= 0x4b do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # OP_PUSHDATA1 The next byte contains the number of bytes to be pushed onto the stack.1
  def parse(script, << @op_pushdata1, size, bin :: binary >>) do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # OP_PUSHDATA2 The next two bytes contain the number of bytes to be pushed onto the stack.
  def parse(_script, << @op_pushdata2, size :: unsigned-little-integer-size(16), _bin :: binary >>) when size > @max_element_size, do: @invalid
  def parse(script, << @op_pushdata2, size :: unsigned-little-integer-size(16), bin :: binary >>) do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # OP_PUSHDATA5 The next four bytes contain the number of bytes to be pushed onto the stack.
  def parse(_script, << @op_pushdata4, size :: unsigned-little-integer-size(32), _bin :: binary >>) when size > @max_element_size, do: @invalid
  def parse(script, << @op_pushdata4, size :: unsigned-little-integer-size(32), bin :: binary >>) do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # Other opcodes
  def parse(script, << op_code, bin :: binary >>) when op_code in @op_values do
    (script ++ [@op_name[op_code]]) |> parse(bin)
  end

  def parse(script, << op_code, bin :: binary >>) when not (op_code in @op_values) do
    (script ++ [:OP_UNKNOWN]) |> parse(bin)
  end

  ##
  ## Binary serialization
  ##

  def to_binary(script) when is_list(script) do
    script
    |> Enum.map(&to_binary_word/1)
    |> Enum.join
  end

  def to_binary_word(word) when is_binary(word) and byte_size(word) >= 0x01 and byte_size(word) <= 0x4b, do: << byte_size(word) >> <> word
  def to_binary_word(word) when is_binary(word) and byte_size(word) <= 0xff , do: << @op_pushdata1, byte_size(word) >> <> word
  def to_binary_word(word) when is_binary(word) and byte_size(word) > @max_element_size , do: {:error, :max_element_size}
  def to_binary_word(word) when is_binary(word), do: << @op_pushdata2, byte_size(word) ::unsigned-little-integer-size(16) >> <> word
  # OP_PUSHDATA4 currently unused because of @max_element_size
  def to_binary_word(word) when word in @op_names, do: << @op[word] >>

  ##
  ## Parsing bitcoind string representation
  ##

  def parse_string(string) do
    string
    |> String.split(" ")
    |> Enum.map(&parse_string_word/1)
  end

  def parse_string_word("1"), do: :OP_TRUE
  def parse_string_word("0"), do: :OP_FALSE
  def parse_string_word(("OP_" <> _) = op_name), do: op_name |> String.to_atom |> parse_string_op_validate
  def parse_string_word(hex), do: hex |> Binary.from_hex
  def parse_string_op_validate(opcode), do: opcode

  def to_string(script) do
    script
    |> Enum.map(&to_string_word/1)
    |> Enum.join(" ")
  end

  def to_string_word(:OP_FALSE), do: "0"
  def to_string_word(:OP_TRUE), do: "1"
  def to_string_word(op) when is_atom(op), do: op |> Kernel.to_string
  def to_string_word(bin) when is_binary(bin), do: bin |> Binary.to_hex

  ##
  ## Parsing alternative string representation
  ##
  ## e.g. 1 0x41 0x04cc71eb30d653c0c3163990c47b976f3fb3f37cccdcbedb169a1dfef58bbfbfaff7d8a473e7e2e6d317b87bafe8bde97e3cf8f065dec022b51d11fcdd0d348ac4 0x41 0x0461cbdcc5409fb4b4d42b51d33381354d80e550078cb532a34bfa2fcfdeb7d76519aecc62770f5b0e4ef8551946d8a540911abe3e7854a26f39f58b25c15342af 2 OP_CHECKMULTISIG
  ## op names can also appear without OP_ prefix

  def parse_string2(string), do: string |> string2_to_binary |> parse

  def string2_to_binary(string) do
    string
    |> String.split(" ")
    |> Enum.filter(& &1 != "")
    |> Enum.map(&parse_string2_word/1)
    |> Enum.join
  end

  # parse_string2_word parses string representation into binary (because it can include pushdata opcodes)
  @short_op_names @op_names |> Enum.map(&to_string/1) |> Enum.map(fn("OP_" <> name) -> name end)
  def parse_string2_word(opcode) when opcode in @short_op_names, do: <<@op[:"OP_#{opcode}"]>>
  def parse_string2_word(("OP_" <> _) = op_name), do: <<@op[op_name |> String.to_atom]>>
  def parse_string2_word("0x" <> hex), do: hex |> Binary.from_hex
  def parse_string2_word("'" <> bin), do: bin |> :binary.part(0, byte_size(bin)-1) |> to_binary_word
  def parse_string2_word(int) do
    {num, _} = int |> Integer.parse
    num |> Bitcoin.Script.Number.bin |> to_binary_word
  end

end
