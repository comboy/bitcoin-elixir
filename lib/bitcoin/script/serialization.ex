defmodule Bitcoin.Script.Serialization do

  # PUSHDATA with size > @max_element_size makes the script invalid
  @max_element_size 520
  @max_script_size 10_000 # scripts > 10,000 bytes are invalid

  @op [ # source https://github.com/bitcoin/bitcoin/blob/master/src/script/script.h
    # push value
    OP_0: 0x00,
    OP_FALSE: 0x00,
    OP_PUSHDATA1: 0x4c,
    OP_PUSHDATA2: 0x4d,
    OP_PUSHDATA4: 0x4e,
    OP_1NEGATE: 0x4f,
    OP_RESERVED: 0x50,
    OP_1: 0x51,
    OP_TRUE: 0x51,
    OP_2: 0x52,
    OP_3: 0x53,
    OP_4: 0x54,
    OP_5: 0x55,
    OP_6: 0x56,
    OP_7: 0x57,
    OP_8: 0x58,
    OP_9: 0x59,
    OP_10: 0x5a,
    OP_11: 0x5b,
    OP_12: 0x5c,
    OP_13: 0x5d,
    OP_14: 0x5e,
    OP_15: 0x5f,
    OP_16: 0x60,

    # control
    OP_NOP: 0x61,
    OP_VER: 0x62,
    OP_IF: 0x63,
    OP_NOTIF: 0x64,
    OP_VERIF: 0x65,
    OP_VERNOTIF: 0x66,
    OP_ELSE: 0x67,
    OP_ENDIF: 0x68,
    OP_VERIFY: 0x69,
    OP_RETURN: 0x6a,

    # stack ops
    OP_TOALTSTACK: 0x6b,
    OP_FROMALTSTACK: 0x6c,
    OP_2DROP: 0x6d,
    OP_2DUP: 0x6e,
    OP_3DUP: 0x6f,
    OP_2OVER: 0x70,
    OP_2ROT: 0x71,
    OP_2SWAP: 0x72,
    OP_IFDUP: 0x73,
    OP_DEPTH: 0x74,
    OP_DROP: 0x75,
    OP_DUP: 0x76,
    OP_NIP: 0x77,
    OP_OVER: 0x78,
    OP_PICK: 0x79,
    OP_ROLL: 0x7a,
    OP_ROT: 0x7b,
    OP_SWAP: 0x7c,
    OP_TUCK: 0x7d,

    # splice ops
    OP_CAT: 0x7e,
    OP_SUBSTR: 0x7f,
    OP_LEFT: 0x80,
    OP_RIGHT: 0x81,
    OP_SIZE: 0x82,

    # bit logic
    OP_INVERT: 0x83,
    OP_AND: 0x84,
    OP_OR: 0x85,
    OP_XOR: 0x86,
    OP_EQUAL: 0x87,
    OP_EQUALVERIFY: 0x88,
    OP_RESERVED1: 0x89,
    OP_RESERVED2: 0x8a,

    # numeric
    OP_1ADD: 0x8b,
    OP_1SUB: 0x8c,
    OP_2MUL: 0x8d,
    OP_2DIV: 0x8e,
    OP_NEGATE: 0x8f,
    OP_ABS: 0x90,
    OP_NOT: 0x91,
    OP_0NOTEQUAL: 0x92,

    OP_ADD: 0x93,
    OP_SUB: 0x94,
    OP_MUL: 0x95,
    OP_DIV: 0x96,
    OP_MOD: 0x97,
    OP_LSHIFT: 0x98,
    OP_RSHIFT: 0x99,

    OP_BOOLAND: 0x9a,
    OP_BOOLOR: 0x9b,
    OP_NUMEQUAL: 0x9c,
    OP_NUMEQUALVERIFY: 0x9d,
    OP_NUMNOTEQUAL: 0x9e,
    OP_LESSTHAN: 0x9f,
    OP_GREATERTHAN: 0xa0,
    OP_LESSTHANOREQUAL: 0xa1,
    OP_GREATERTHANOREQUAL: 0xa2,
    OP_MIN: 0xa3,
    OP_MAX: 0xa4,

    OP_WITHIN: 0xa5,

    # crypto
    OP_RIPEMD160: 0xa6,
    OP_SHA1: 0xa7,
    OP_SHA256: 0xa8,
    OP_HASH160: 0xa9,
    OP_HASH256: 0xaa,
    OP_CODESEPARATOR: 0xab,
    OP_CHECKSIG: 0xac,
    OP_CHECKSIGVERIFY: 0xad,
    OP_CHECKMULTISIG: 0xae,
    OP_CHECKMULTISIGVERIFY: 0xaf,

    # expansion
    OP_NOP1: 0xb0,
    OP_CHECKLOCKTIMEVERIFY: 0xb1,
    OP_NOP2: 0xb1,
    OP_CHECKSEQUENCEVERIFY: 0xb2,
    OP_NOP3: 0xb2,
    OP_NOP4: 0xb3,
    OP_NOP5: 0xb4,
    OP_NOP6: 0xb5,
    OP_NOP7: 0xb6,
    OP_NOP8: 0xb7,
    OP_NOP9: 0xb8,
    OP_NOP10: 0xb9,

    # template matching params
    OP_SMALLINTEGER: 0xfa,
    OP_PUBKEYS: 0xfb,
    OP_PUBKEYHASH: 0xfd,
    OP_PUBKEY: 0xfe,

    OP_INVALIDOPCODE: 0xff
  ]

  @op |> Enum.map(fn {op, val} -> Module.put_attribute(__MODULE__, op |> to_string |> String.downcase |> String.to_atom, val) end)

  @op_values @op |> Keyword.values
  @op_names @op |> Keyword.keys

  @op_name @op |> Enum.map(fn {k,v} -> {v,k} end) |> Enum.into(%{})

  @disabled_op [
    :OP_CAT,
    :OP_SUBSTR,
    :OP_LEFT,
    :OP_RIGHT,
    :OP_INVERT,
    :OP_AND,
    :OP_OR,
    :OP_XOR,
    :OP_2MUL,
    :OP_2DIV,
    :OP_MUL,
    :OP_DIV,
    :OP_MOD,
    :OP_LSHIFT,
    :OP_RSHIFT,
    :OP_VERIF,
    :OP_VERNOTIF
  ]

  @disabled_op_values @disabled_op |> Enum.map(fn name -> @op[name] end)

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
       e in MatchError -> @invalid
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
  def parse(script, << @op_pushdata2, size :: unsigned-little-integer-size(16), bin :: binary >>) when size > @max_element_size, do: @invalid
  def parse(script, << @op_pushdata2, size :: unsigned-little-integer-size(16), bin :: binary >>) do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # OP_PUSHDATA5 The next four bytes contain the number of bytes to be pushed onto the stack.
  def parse(script, << @op_pushdata4, size :: unsigned-little-integer-size(32), bin :: binary >>) when size > @max_element_size, do: @invalid
  def parse(script, << @op_pushdata4, size :: unsigned-little-integer-size(32), bin :: binary >>) do
    << data :: binary-size(size), bin :: binary >> = bin
    (script ++ [data]) |> parse(bin)
  end

  # Disabled opcodes
  def parse(script, << op_code, bin :: binary >>) when op_code in @disabled_op_values, do: @invalid

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
    script = string
      |> String.split(" ")
      |> Enum.map(&parse_string_word/1)
      |> Enum.reverse
      |> Enum.reduce([], fn(x, r) ->
        cond do
          x == :invalid      -> @invalid
          r == @invalid -> @invalid
          true               -> [x | r]
        end
      end)
  end

  def parse_string_word("1"), do: :OP_TRUE
  def parse_string_word("0"), do: :OP_FALSE
  def parse_string_word(("OP_" <> _) = op_name), do: op_name |> String.to_atom |> parse_string_op_validate
  def parse_string_word(hex), do: hex |> String.upcase |> Base.decode16!
  def parse_string_op_validate(opcode) when opcode in @disabled_op, do: :invalid
  def parse_string_op_validate(opcode), do: opcode

end
