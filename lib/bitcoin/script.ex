defmodule Bitcoin.Script do

  @moduledoc """
    Bitcoin Script interpreter.

    Opcodes numbers are coming from: https://github.com/bitcoin/bitcoin/blob/master/src/script/script.h

    Implemented from the scratch based on the wiki (https://en.bitcoin.it/wiki/Script)
    and script test cases from bitcoinj/bitcore.

    There is still a long road ahead to 100% of valid/invalid scripts test suite (it's really good).
    List of issues to remember can be find in the source file with an upcase 'todo' tag.

    Script.Serialization handles parsing the script from a binary into a list with opcodes as symbols.

    Script.Control implements parsing OP_IF

    Script.Number handles parsing and serializing script integers (CStriptNum)
  """

  # TODO max ops count = 201 - opts can be used to easily increase counter
  # TODO block sigop limit (MAX_BLOCK_SIGOPS = MAX_BLOCK_SIZE/50), so we need to be abel to export that count
  # TODO verify signature encoding https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki

  alias Bitcoin.Script.Serialization

  defdelegate parse(binary), to: Serialization
  defdelegate to_binary(script), to: Serialization
  defdelegate parse_string(script), to: Serialization
  defdelegate parse_string2(script), to: Serialization

  import Bitcoin.Script.Macros
  import Bitcoin.Script.Control
  import Bitcoin.Script.Number

  use Bitcoin.Script.Opcodes
  use Bitcoin.Script.P2SH

  # Max number of items in stack + altstack
  @max_stacks_size 1000
  @max_pubkeys_per_multisig 20
  # Max number of opcodes that can be present in the script
  # (excluding opcodes with byte value equal or below OP_16)
  @max_ops 201

  # The reason for this function is that we need to parse sig script and pk separately.
  # Otherwise sig script could do some nasty stuff with malformed PUSHDATA
  # Then we have to run it separately
  def verify_sig_pk(sig_bin, pk_bin, opts \\[])
  def verify_sig_pk(sig_bin, pk_bin, opts) when is_binary(sig_bin) and is_binary(pk_bin), do: verify_sig_pk(sig_bin |> parse, pk_bin |> parse, opts)
  def verify_sig_pk(sig_script, pk_script, opts) do
    try do
      sig_script
      |> run(opts)
      |> run(pk_script, opts)
      |> cast_to_bool
    catch _,_ ->
      false
    end
  end

  # Returns true if top item of the stack is non-zero
  def verify(script, opts \\ []) do
    # TODO we should get rid of exceptions, make parser return {:error and non matched script cases should just be :invalid
    try do
      script |> run(opts) |> cast_to_bool
    catch _, _ ->
      false
    end
  end

  # Cast stack to boolean
  def cast_to_bool(:invalid), do: false
  def cast_to_bool([]), do: false
  def cast_to_bool([0 | _]), do: false
  def cast_to_bool([<<>> | _]), do: false
  def cast_to_bool([_ | _]), do: true

  # Header declaration for function with default value and multiple clauses
  def run(script, opts \\ [])

  # When binary is provided, parse it and then run
  def run(binary, opts) when is_binary(binary), do: binary |> parse |> run(opts)

  # Run the parsed script
  def run(script, opts), do: run([], script |> validate, opts)

  # Opcodes return :invalid instead of returning new stack in case execution should stop and script should fail
  # Parser returns [:invalid] if the script couldn't be parsed
  def run(:invalid, _script, _opts), do: :invalid
  def run(_, [:invalid | _], _opts), do: :invalid

  # Stack size limit
  # TODO should include altstack
  def run(stack, _script, _opts) when length(stack) > @max_stacks_size, do: :invalid

  # When no script is left to run, return the stack
  def run(stack, [], _opts), do: stack

  # Binary blob, put it on the stack
  def run(stack, [data | script], opts) when is_binary(data) or is_number(data), do: run([data | stack], script, opts)

  # VAlidate sanityf of the script
  # We should probably switch to a single run through script like in bitcoin core
  def validate(script) do
    cond do
      # Script invalid if any of disabled ops is present
      script |> Enum.any?(fn op -> op in @disabled_op end) -> [:invalid]
      # Scirpt max ops
      script |> length > @max_ops -> [:invalid] # TODO op count excludes OP_1 - OP_16
      true -> script
    end
  end

  ##
  ## PUSH VALUE
  ##

  op_push :OP_TRUE,  1
  op_push :OP_FALSE, 0

  op_push :OP_1NEGATE, -1

  op_push :OP_1,  1
  op_push :OP_2,  2
  op_push :OP_3,  3
  op_push :OP_4,  4
  op_push :OP_5,  5
  op_push :OP_6,  6
  op_push :OP_7,  7
  op_push :OP_8,  8
  op_push :OP_9,  9
  op_push :OP_10, 10
  op_push :OP_11, 11
  op_push :OP_12, 12
  op_push :OP_13, 13
  op_push :OP_14, 14
  op_push :OP_15, 15
  op_push :OP_16, 16

  ##
  ## CONTROL
  ##

  # OP_NOP Does nothing
  op :OP_NOP, stack, do: stack

  # OP_RESERVED Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_RESERVED, _, do: :invalid

  # OP_VER Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_VER, _, do: :invalid

  # OPVERIF Transaction is invalid even when occuring in an unexecuted OP_IF branch
  # Because of that, it's handled by the parser same as disabled OPs
  op :OP_VERIF, _, do: :invalid

  # OPVERIF transaction is invalid even when occuring in an unexecuted OP_IF branch
  # Because of that, it's handled by the parser same as disabled OPs
  op :OP_VERNOTIF, _, do: :invalid

  # OP_IF If the top stack value is not False, the statements are executed. The top stack value is removed.
  def run([0 | stack], [:OP_IF | script], opts), do: stack |> run(script |> extract_else, opts)
  def run([_ | stack], [:OP_IF | script], opts), do: stack |> run(script |> extract_if, opts)

  # OP_NOTIF If the top stack value is False, the statements are executed. The top stack value is removed.
  # Not the same as OP_NOT then OP_IF because OP_NOT should only work on numbers
  def run([0 | stack], [:OP_NOTIF | script], opts), do: stack |> run(script |> extract_if, opts)
  def run([_ | stack], [:OP_NOTIF | script], opts), do: stack |> run(script |> extract_else, opts)

  # OP_ELSE implemented as part of the OP_IF

  # OP_VERIFY Marks transaction as invalid if top stack value is not true.
  op :OP_VERIFY, [0 | _], do: :invalid
  op :OP_VERIFY, [_ | stack], do: stack

  # OP_RETURN Marks transaction as invalid.
  op :OP_RETURN, _, do: :invalid

  ##
  ## STACKOPS
  ##

  # OP_TOALTSTACK   Puts the input onto the top of the alt stack. Removes it from the main stack.
  def run([x | stack], [:OP_TOALTSTACK | script], opts) do
    alt = opts[:alt] || []
    stack |> run(script, opts |> Keyword.put(:alt, [x | alt]))
  end

  # OP_FROM_LTSTACK Puts the input onto the top of the main stack. Removes it from the alt stack.
  def run(stack, [:OP_FROMALTSTACK | script], opts) do
    [x | alt] = opts[:alt]
    [x | stack] |> run(script, opts |> Keyword.put(:alt, alt))
  end

  # OP_2DROP Removes the top two stack items.
  op :OP_2DROP, [_, _ | stack], do: stack

  # OP_2DUP Duplicates the top two stack items
  op :OP_2DUP,  [a, b | stack], do: [a, b, a, b | stack]

  # OP_3DUP Duplicates the top two stack items
  op :OP_3DUP,  [a, b, c | stack], do: [a, b, c, a, b, c | stack]

  # OP_2OVER Copies the pair of items two spaces back in the stack to the front.
  op :OP_2OVER, [_a, _b, c, d | _] = stack, do: [c, d] ++ stack

  # OP_2ROT The fifth and sixth items back are moved to the top of the stack.
  op :OP_2ROT,  [a, b, c, d, e, f | stack], do: [e, f, a, b, c, d | stack]

  # OP_2SWAP Swaps the top two pairs of items.
  op :OP_2SWAP, [a, b, c, d | stack], do: [c, d, a, b | stack]

  # OP_IFDUP IF the top stack value is not 0, duplicate it
  op :OP_IFDUP, [0 | stack], do: [0 | stack]
  op :OP_IFDUP, [x | stack], do: [x, x | stack]

  # OP_DEPTH Puts the number of stack items onto the stack
  op :OP_DEPTH, stack, do: [stack |> length | stack]

  # OP_DROP Removes the top stack item.
  op :OP_DROP, [_ | stack], do: stack

  # OP_DUP Duplicates the top stack item.
  op :OP_DUP, [x | stack], do: [x, x | stack]

  # OP_NIP Removes the second-to-top stack item
  op :OP_NIP, [a, _b | stack], do: [a | stack]

  # OP_OVER Copies the second-to-top stack item to the top.
  op :OP_OVER, [a, b | stack], do: [b, a, b | stack]

  # OP_PICK The item n back in the stack is copied to the top
  op :OP_PICK, [n | stack], do: [stack |> Enum.at(num(n)) | stack]

  # OP_ROLL The item n back in the stack is moved to the top.
  op :OP_ROLL, [n | stack], do: [stack |> Enum.at(num(n)) | stack |> List.delete_at(num(n))]

  # OP_ROT The top three items on the stack are rotated to the left.
  op :OP_ROT, [a, b, c | stack], do: [c, a, b | stack]

  # OP_SWAP The top two items on the stack are swapped.
  op :OP_SWAP, [a, b | stack], do: [b, a | stack]

  # OP_TUCK The item at the top of the stack is copied and inserted before the second-to-top item.
  op :OP_TUCK, [a, b | stack],do: [a, b, a | stack]


  ##
  ## SPLICE OPS
  ##

  # OP_CAT disabled
  # OP_SUBSTR disabled
  # OP_LEFT disabled
  # OP_RIGHT disabled

  # OP_SIZE Pushes the string length of the top element of the stack (without popping it)
  op :OP_SIZE, [<< x :: binary >> | stack], do: [byte_size(x), x | stack]
  op :OP_SIZE, [0 | stack], do: [0, 0 | stack]
  op :OP_SIZE, [x | stack], do: [1, x | stack]

  ##
  ## BIT LOGIC
  ##

  # OP_INVERT disabled
  # OP_AND disabled
  # OP_OR disabled
  # OP_XOR disabled

  # OP_EQUAL Returns 1 if the inputs are exactly equal, 0 otherwise.
  # These convoluted cases below come from the fact that we keep 0 and 1 on the stack
  # intsead of <<>> and <<1>> (same for OP_1-16, We should switch to proper representation on the stack
  op :OP_EQUAL, [a, b | stack] when is_binary(a) and is_binary(b), do: [(if a == b, do: 1, else: 0) | stack]
  op :OP_EQUAL, [a, b | stack] when is_number(a) and is_binary(b), do: [(if bin(a) == b, do: 1, else: 0) | stack]
  op :OP_EQUAL, [a, b | stack] when is_binary(a) and is_number(b), do: [(if a == bin(b), do: 1, else: 0) | stack]
  op :OP_EQUAL, [a, b | stack] when is_number(a) and is_number(b), do: [(if bin(a) == bin(b), do: 1, else: 0) | stack]


  # OP_EQUALVERIFY Same as OP_EQUAL, but runs OP_VERIFY afterward
  op_alias :OP_EQUALVERIFY, [:OP_EQUAL, :OP_VERIFY]

  # OP_RESERVED1 Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_RESERVED1, _, do: :invalid

  # OP_RESERVED2 Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_RESERVED2, _, do: :invalid

  ##
  ## NUMERIC
  ##

  # OP_1ADD 1 is added to the input.
  op_num :OP_1ADD, x, do: x + 1

  # OP_1ADD 1 is substracted from the input.
  op_num :OP_1SUB, x, do: x - 1

  # OP_2MUL disabled
  # OP_2DIV disabled

  # OP_NEGATE The sign of the input is flipped.
  op_num :OP_NEGATE, x, do: -1 * x

  # OP_ABS The input is made positive.
  op_num :OP_ABS, x, do: x |> abs

  # OP_NOT If the input is 0 or 1, it is flipped. Otherwise the output will be 0.
  op_num :OP_NOT, 0, do: 1
  op_num :OP_NOT, 1, do: 0
  op_num :OP_NOT, x, do: 0

  # OP_0NOTEQUAL 	Returns 0 if the input is 0. 1 otherwise.
  op_num :OP_0NOTEQUAL, 0, do: 0
  op_num :OP_0NOTEQUAL, x, do: 1

  # OP_ADD a is added to be
  op_num :OP_ADD, a, b, do: a + b

  # OP_SUB a is substracted from b
  op_num :OP_SUB, a, b, do: b - a

  # OP_MUL disabled
  # OP_DIV disabled
  # OP_MOD disabled
  # OP_LSHIFT disabled
  # OP_RSHIFT disabled

  # OP_BOOLAND If both a and b are not 0, the output is 1. Otherwise 0.
  # We cast to num because it's in arithmetic ops category, so it should fail if arg is not a proper int
  op_bool :OP_BOOLAND, a, b, do: num(a) != 0 and num(b) != 0

  # OP_BOOLOR If a or b is not 0, the output is 1. Otherwise 0.
  op_bool :OP_BOOLOR, a, b, do: num(a) != 0 or num(b) != 0

  # OP_NUMEQUAL Returns 1 if the numbers are equal, 0 otherwise.
  op_bool :OP_NUMEQUAL, a, b, do: num(a) == num(b)

  # OP_NUMNOTEQUAL Returns 1 if the numbers are not equal, 0 otherwise.
  op_bool :OP_NUMNOTEQUAL, a, b, do: num(a) != num(b)

  # OP_NUMEQUAVERIFY Same as OP_NUMEQUAL, but runs OP_VERIFY afterward.
  op_alias :OP_NUMEQUALVERIFY, [:OP_NUMEQUAL, :OP_VERIFY]

  # OP_NUMLESSTHAN Returns 1 if a is less than b, 0 otherwise.
  op_bool :OP_LESSTHAN, b, a, do: num(a) < num(b)

  # OP_NUMGREATERTHAN Returns 1 if a is greater than b, 0 otherwise.
  op_bool :OP_GREATERTHAN, b, a, do: num(a) > num(b)

  # OP_NUMLESSTHANOREQUAL Returns 1 if a is less than  or equal b, 0 otherwise.
  op_bool :OP_LESSTHANOREQUAL, b, a, do: num(a) <= num(b)

  # OP_NUMGREATERTHANOREQUAL Returns 1 if a is greater than b, 0 otherwise.
  op_bool :OP_GREATERTHANOREQUAL, b, a, do: num(a) >= num(b)

  # OP_MIN Returns the smaller of a and b
  op :OP_MIN, [a, b | stack], do: [(if (num(a) <=  num(b)), do: a, else: b) | stack]

  # OP_MOX Returns the bigger of a and b
  op :OP_MAX, [a, b | stack], do: [(if (num(a) >=  num(b)), do: a, else: b) | stack]

  # OP_WITHIN Returns 1 if x is within the specified range (left-inclusive), 0 otherwise.
  op_bool :OP_WITHIN, b, a, x, do: num(x) >= num(a) and num(x) < num(b)

  ##
  ## CRYPTO
  ##

  # OP_RIPEMD160 The input is hashed using RIPEMD-160.
  op :OP_RIPEMD160, [x | stack], do: [:crypto.hash(:ripemd160, bin(x)) | stack]

  # OP_SHA1 The input is hashed using SHA-1.
  op :OP_SHA1, [x | stack], do: [:crypto.hash(:sha, bin(x)) | stack]

  # OP_SHA256 The input is hashed using SHA-256
  op :OP_SHA256, [x | stack], do: [:crypto.hash(:sha256, bin(x)) | stack]

  # OP_HASH160 The input is hashed twice: first with SHA-256 and then with RIPEMD-160.
  op :OP_HASH160, [x | stack], do: [:crypto.hash(:ripemd160, :crypto.hash(:sha256, bin(x))) | stack]

  # OP_HASH256 The input is hashed two times with SHA-256.
  op :OP_HASH256, [x | stack], do: [:crypto.hash(:sha256, :crypto.hash(:sha256, bin(x))) | stack]

  # TODO OP_CODESEPARATOR All of the signature checking words will only match signatures
  # to the data after the most recently-executed OP_CODESEPARATOR.
  op :OP_CODESEPARATOR, stack, do: stack

  # OP_CHECKSIG The entire transaction's outputs, inputs, and script (from the most recently-executed OP_CODESEPARATOR
  # to the end) are hashed. The signature used by OP_CHECKSIG must be a valid signature for this hash and public key.
  # If it is, 1 is returned, 0 otherwise.
  op :OP_CHECKSIG, [pk, sig | stack], opts, do: [verify_signature(sig, pk, opts) |> bool | stack]

  # OP_CHEKSIGVERIFY Same as OP_CHECKSIG, but OP_VERIFY is executed afterward.
  op_alias :OP_CHECKSIGVERIFY, [:OP_CHECKSIG, :OP_VERIFY]

  # Used to get multiple keys or signatures from the stack
  # First item is the number of them and then it's alist of binaries
  # Returs {items, remaining_stack}
  def get_multi([ n | stack]), do: stack |> Enum.split(num(n))

  # OP_CHECKMULTISIG
  # Compares the first signature against each public key until it finds an ECDSA match.
  # Starting with the subsequent public key, it compares the second signature against each remaining public key
  # until it finds an ECDSA match. The process is repeated until all signatures have been checked or not enough
  # public keys remain to produce a successful result. All signatures need to match a public key. Because public
  # keys are not checked again if they fail any signature comparison, signatures must be placed in the scriptSig
  # using the same order as their corresponding public keys were placed in the scriptPubKey or redeemScript.
  # If all signatures are valid, 1 is returned, 0 otherwise.
  op :OP_CHECKMULTISIG, stack, opts do
    {pks, stack} = stack |> get_multi
    {sigs, stack} = stack |> get_multi
    # TODO when BIP 147 applies (:nulldummy flag), ensure that _bug == <<>>
    [_bug | stack] = stack # Due to a bug, one extra unused value is removed from the stack.

    # with nsigs > npubkeys it must make the script invalid (it's not enough that it returns false)
    # same if number of pubkeys is > 20
    if length(pks) > @max_pubkeys_per_multisig || length(sigs) > length(pks) do
      :invalid
    else
      [verify_all_signatures(sigs, pks, opts) |> bool | stack]
    end
  end

  # Same as OP_CHECKMULTISIG, but OP_VERIFY is executed afterward.
  op_alias :OP_CHECKMULTISIGVERIFY, [:OP_CHECKMULTISIG, :OP_VERIFY]

  ##
  ## EXPANSION
  ###

  # OP_NOP1-10 No-op
  op :OP_NOP1, stack, do: stack
  # TODO OP_CHECKLOCKTIMEVERIFY
  op :OP_NOP2, stack, do: stack
  # TODO OP_CHECKSEQUENCEVERIFY
  op :OP_NOP3, stack, do: stack
  op :OP_NOP4, stack, do: stack
  op :OP_NOP5, stack, do: stack
  op :OP_NOP6, stack, do: stack
  op :OP_NOP7, stack, do: stack
  op :OP_NOP8, stack, do: stack
  op :OP_NOP9, stack, do: stack
  op :OP_NOP10, stack, do: stack

  ## TEMPLATE MATCHING PARAMS ?
  # no idea wee need to do anything with those from script.h
  #
  # OP_SMALLINTEGER
  # OP_PUBKEYS
  # OP_PUBKEYHASH
  # OP_PUBKEY
  # OP_INVALIDOPCODE

  # Helper to cast boolean result operations to resulting stack element
  def bool(true), do: 1
  def bool(false), do: 0

  def verify_signature(sig, pk, opts) do
    # Last byte is a sighash_type, read it and remove it
    sighash_type = sig |> :binary.at(byte_size(sig)-1)
    sig = sig |> :binary.part(0, byte_size(sig)-1)
    # Generate sighash (with only single sha256)
    sighash = opts[:tx] |> Bitcoin.Tx.sighash(opts[:input_number], opts[:sub_script], sighash_type)
    # Do sha256 again and verify
    :crypto.verify(:ecdsa, :sha256, sighash, sig, [pk, :secp256k1])
  end

  # No sigs to verify
  def verify_all_signatures([], _, _opts), do: true
  # No PKs to verify against, but there are still some sigs (previous match gets rid of [])
  def verify_all_signatures(_, [], _opts), do: false
  def verify_all_signatures([sig | sigs], [pk | pks], opts) do
    case verify_signature(sig, pk, opts) do
      # Verification succeeded, move to the next sig
      true  -> verify_all_signatures(sigs, pks, opts)
      # Verification failed, try the next PK
      false -> verify_all_signatures([sig | sigs], pks, opts)
    end
  end

end
