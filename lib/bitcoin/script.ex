defmodule Bitcoin.Script do

  @moduledoc """
    Bitcoin Script interpreter.

    Opcodes numbers are coming from: https://github.com/bitcoin/bitcoin/blob/master/src/script/script.h

    Implemented from the scratch based on the wiki (https://en.bitcoin.it/wiki/Script)
    and script test cases from bitcoinj/bitcore.

    There is still a long road ahead to 100% of valid/invalid scripts test suite (it's really good).
    List of issues to remember can be find in the source file with an upcase 'todo' tag.

    Script.Binary handles parsing the script from a binary into a list with opcodes as symbols.

    op macro is just a shorthand for defining another case of the `run` function. To be super clear:

        op :OP_DUP, [x | stack], do: [x, x | stack]

    expands to

        run([x | stack], [:OP_DUP | script], opts), do: [x, x | stack] |> run(script, opts)

  """

  # TODO max ops count = 201 - opts can be used to easily increase counter
  # TODO block sigop limit (MAX_BLOCK_SIGOPS = MAX_BLOCK_SIZE/50), so we need to be abel to export that count

  # Notes
  #
  # OP_MIN case that seems not coveredi in tests:
  # a and b are the same number but with a different binary representation, which should we return if they are equal?
  # (could matter if next op is e.g. OP_SIZE)
  #
  # OP_BOOLOR and others, should we check if 0 is maybe represented as  more than 1 byte long binary?


  alias Bitcoin.Script.Binary

  import Bitcoin.Script.Macros


  @invalid_unexecuted [:OP_VERIF, :OP_VERNOT_IF]

  @doc """
    Run the provided script and evaluate to boolean.

    Opts can be used to set the context of teh script (e.g. [tx: %Messages.Tx{}])
  """
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
  def cast_to_bool([_ | _]), do: true

  # Header declaration for function with default value and multiple clauses
  def run(script, opts \\ [])

  # When binary is provided, parse it and then run
  def run(binary, opts) when is_binary(binary) do
    case binary |> Binary.parse do
       {:error, :invalid} -> :invalid
       script -> script |> run(opts)
    end
  end

  # Run the parsed script
  def run(script, opts), do: run([], script, opts)

  # Opcodes return :invalid instead of returning new stack in case execution should stop and script should fail
  def run(:invalid, _script), do: :invalid

  # When no script is left to run, return the stack
  def run(stack, [], _opts), do: stack

  # Binary blob, put it on the stack
  def run(stack, [data | script], opts) when is_binary(data) or is_number(data), do: run([data | stack], script, opts)

  ##
  ## PUSH VALUE
  ##

  op :OP_TRUE, stack, do: [1 | stack]
  op :OP_FALSE, stack, do: [0 | stack]

  op :OP_1NEGATE, stack, do: [-1 | stack]

  op :OP_1,  stack, do: [1 | stack]
  op :OP_2,  stack, do: [2 | stack]
  op :OP_3,  stack, do: [3 | stack]
  op :OP_4,  stack, do: [4 | stack]
  op :OP_5,  stack, do: [5 | stack]
  op :OP_6,  stack, do: [6 | stack]
  op :OP_6,  stack, do: [6 | stack]
  op :OP_7,  stack, do: [7 | stack]
  op :OP_8,  stack, do: [8 | stack]
  op :OP_9,  stack, do: [9 | stack]
  op :OP_10, stack, do: [10 | stack]
  op :OP_11, stack, do: [11 | stack]
  op :OP_12, stack, do: [12 | stack]
  op :OP_13, stack, do: [13 | stack]
  op :OP_14, stack, do: [14 | stack]
  op :OP_15, stack, do: [15 | stack]
  op :OP_16, stack, do: [16 | stack]

  ##
  ## CONTROL
  ##

  # OP_NOP Does nothing
  op :OP_NOP, stack, do: stack

  # OP_VER Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OF_VER, _, do: :invalid

  # OPVERIF ransaction is invalid even when occuring in an unexecuted OP_IF branch
  # TODO this will need special handling when if is implemented
  op :OP_VERIF, _, do: :invalid

  # OPVERIF ransaction is invalid even when occuring in an unexecuted OP_IF branch
  # TODO this will need special handling when if is implemented
  op :OP_VERNOTIF, _, do: :invalid

  # OP_IF If the top stack value is not False, the statements are executed. The top stack value is removed.
  def run([0 | stack], [:OP_IF | script], opts), do: stack |> run_else(script, opts)
  def run([x | stack], [:OP_IF | script], opts), do: stack |> run_if(script, opts)

  # OP_NOTIF If the top stack value is False, the statements are executed. The top stack value is removed.
  def run([0 | stack], [:OP_NOTIF | script], opts), do: stack |> run_if(script, opts)
  def run([_ | stack], [:OP_NOTIF | script], opts), do: stack |> run_else(script, opts)

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
  op :OP_ROT, [a, b, c | stack], do: [b, c, a | stack]

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
  def run([a, b | stack], [:OP_EQUAL | script], opts) when is_binary(a) and is_binary(b), do: [(if a == b, do: 1, else: 0), a, b | stack] |> run(script, opts)
  op :OP_EQUAL, [a, b | stack], do: [(if num(a) == num(b), do: 1, else: 0), a, b | stack]


  # OP_EQUALVERIFY Same as OP_EQUAL, but runs OP_VERIFY afterward
  def run([a, b | stack], [:OP_EQUALVERIFY | script], opts) when a != b, do: [0 | stack]
  def run([a, b | stack], [:OP_EQUALVERIFY | script], opts) when a == b, do: stack |> run(script, opts)

  # OP_RESERVED1 Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_RESERVED1, _, do: :invalid

  # OP_RESERVED2 Transaction is invalid unless occuring in an unexecuted OP_IF branch
  op :OP_RESERVED2, _, do: :invalid

  ##
  ## NUMERIC
  ##

  def num(<< x :: signed-little-integer-size(32) >>), do: x
  def num(<< x :: signed-little-integer-size(24) >>), do: x
  def num(<< x :: signed-little-integer-size(16) >>), do: x
  def num(<< x :: signed-little-integer-size(8) >>), do: x
  def num(x) when is_number(x), do: x

  # OP_1ADD 1 is added to the input.
  op :OP_1ADD, [x | stack], do: [num(x) + 1 | stack]

  # OP_1ADD 1 is substracted from the input.
  op :OP_1SUB, [x | stack], do: [num(x) - 1 | stack]

  # OP_2MUL disabled
  # OP_2DIV disabled

  # OP_NEGATE The sign of the input is flipped.
  op :OP_NEGATE, [x | stack], do: [-1 * num(x) | stack]

  # OP_ABS The input is made positive.
  op :OP_ABS, [x | stack], do: [ num(x) |> abs | stack]

  # OP_NOT If the input is 0 or 1, it is flipped. Otherwise the output will be 0.
  op :OP_NOT, [0 | stack], do: [1 | stack]
  op :OP_NOT, [1 | stack], do: [0 | stack]
  op :OP_NOT, [_ | stack], do: [0 | stack]

  # OP_0NOTEQUAL 	Returns 0 if the input is 0. 1 otherwise.
  op :OP_0NOTEQUAL, [0 | stack], do: [0 | stack]
  op :OP_0NOTEQUAL, [_ | stack], do: [1 | stack]

  # OP_ADD a is added to be
  op :OP_ADD, [a, b | stack], do: [num(a) + num(b) | stack]

  # OP_SUB b is substracted from a
  op :OP_SUB, [a, b | stack], do: [num(a) - num(b) | stack]

  # OP_MUL disabled
  # OP_DIV disabled
  # OP_MOD disabled
  # OP_LSHIFT disabled
  # OP_RSHIFT disabled

  # OP_BOOLAND If both a and b are not 0, the output is 1. Otherwise 0.
  op :OP_BOOLAND, [0, 0 | stack], do: [1 | stack]
  op :OP_BOOLAND, [_, _ | stack], do: [0 | stack]

  # OP_BOOLOR If a or b is not 0, the output is 1. Otherwise 0.
  op :OP_BOOLOR, [0, 0 | stack], do: [0 | stack]
  op :OP_BOOLOR, [_, 0 | stack], do: [0 | stack]
  op :OP_BOOLOR, [0, _ | stack], do: [0 | stack]
  op :OP_BOOLOR, [_, _ | stack], do: [1 | stack]

  # OP_NUMEQUAL Returns 1 if the numbers are equal, 0 otherwise.
  op :OP_NUMEQUAL, [a, b | stack], do: [(if num(a) == num(b), do: 1, else: 0) | stack]

  # OP_NUMNOTEQUAL Returns 1 if the numbers are not equal, 0 otherwise.
  op :OP_NUMNOTEQUAL, [a, b | stack], do: [(if num(a) != num(b), do: 1, else: 0) | stack]

  # OP_NUMEQUAVERIFY Same as OP_NUMEQUAL, but runs OP_VERIFY afterward.
  op :OP_NUMEQUALVERIFY, [a, b | stack], do: if num(a) == num(b), do: stack, else: :invalid

  # OP_NUMLESSTHAN Returns 1 if a is less than b, 0 otherwise.
  op :OP_LESSTHAN, [b, a | stack], do: [(if num(a) < num(b), do: 1, else: 0) | stack]

  # OP_NUMGREATERTHAN Returns 1 if a is greater than b, 0 otherwise.
  op :OP_GREATERTHAN, [b, a | stack], do: [(if num(a) > num(b), do: 1, else: 0) | stack]

  # OP_NUMLESSTHANOREQUAL Returns 1 if a is less than  or equal b, 0 otherwise.
  op :OP_LESSTHANOREQUAL, [b, a | stack], do: [(if num(a) <= num(b), do: 1, else: 0) | stack]

  # OP_NUMGREATERTHANOREQUAL Returns 1 if a is greater than b, 0 otherwise.
  op :OP_GREATERTHANOREQUAL, [b, a | stack], do: [(if num(a) >= num(b), do: 1, else: 0) | stack]

  # OP_MIN Returns the smaller of a and b
  op :OP_MIN, [a, b | stack], do: [(if (num(a) <=  num(b)), do: a, else: b) | stack]

  # OP_MOX Returns the bigger of a and b
  op :OP_MAX, [a, b | stack], do: [(if (num(a) >=  num(b)), do: a, else: b) | stack]

  # OP_WITHIN Returns 1 if x is within the specified range (left-inclusive), 0 otherwise.
  op :OP_WITHIN, [b, a, x | stack], do: [(if num(x) >= num(a) && num(x) < num(b), do: 1, else: 0) | stack]

  ##
  ## CRYPTO
  ##

  # Convert stack element to binary - necessary for it to work as an input to crypto functions
  def bin(x) when is_binary(x), do: x
  def bin(x), do: <<x>>

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

  # TODO OP_CODESEPARATOR All of the signature checking words will only match signatures to the data after the most recently-executed OP_CODESEPARATOR.
  op :OP_CODESEPARATOR, stack, do: stack

  # TODO OP_CHECKSIG The entire transaction's outputs, inputs, and script (from the most recently-executed OP_CODESEPARATOR to the end) are hashed. The signature used by OP_CHECKSIG must be a valid signature for this hash and public key. If it is, 1 is returned, 0 otherwise.
  # TODO introduce context
  # XXX always true
  op :OP_CHECKSIG, [sig, pubkey | stack], do: [1 | stack]

  # TODO OP_CHEKSIGVERIFY Same as OP_CHECKSIG, but OP_VERIFY is executed afterward.
  # XXX always true
  op :OP_CHECKSIGVERIFY, [sig, pubkey | stack], do: stack

  # Used to get multiple keys or signatures from the stack
  # First item is the number of them and then it's alist of binaries
  # Returs {items, remaining_stack}
  def get_multi([ n | stack]), do: stack |> Enum.split(num(n))

  # TODO OP_CHECKMULTISIG
  # XXX always true
  # Compares the first signature against each public key until it finds an ECDSA match.
  # Starting with the subsequent public key, it compares the second signature against each remaining public key
  # until it finds an ECDSA match. The process is repeated until all signatures have been checked or not enough
  # public keys remain to produce a successful result. All signatures need to match a public key. Because public
  # keys are not checked again if they fail any signature comparison, signatures must be placed in the scriptSig
  # using the same order as their corresponding public keys were placed in the scriptPubKey or redeemScript.
  # If all signatures are valid, 1 is returned, 0 otherwise.
  #
  # Due to a bug, one extra unused value is removed from the stack.
  op :OP_CHECKMULTISIG, stack do
    {keys, stack} = get_multi(stack)
    {sigs, stack} = get_multi(stack)
    [_bug | stack] = stack
    [1 | stack]
  end

  # TODO OP_CHECKMULTISIGVERIFY
  # XXX Always true
  # Same as OP_CHECKMULTISIG, but OP_VERIFY is executed afterward.
  op :OP_CHECKMULTISIGVERIFY, stack do
    {keys, stack} = get_multi(stack)
    {sigs, stack} = get_multi(stack)
    [_bug | stack] = stack
    stack
  end

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


  # IF STATEMENT IMPLEMENTATION
  #
  # OP_IFs can be nested, which complicates running script a bit.
  #
  # Just going sequentially through it we would have to track some complicated state,
  # especially given that there can be multiple OP_ELSEs.
  #
  # So instead function `parse_if` finds the matching OP_ELSEs (if present) and OP_ENDIF,
  # and returns scripts associated with `if` block part and `else` block part. For multiple
  # OP_ELSE statements, those that execute when `if` block is executed are appended to the
  # if` block script, and others to the `else` block script

  # Run the if block of the provided script which was prepended by OP_IF or OP_NOTIF
  def run_if(stack, script, opts) do
    {if_script, _else_script, script} = parse_if(script)
    stack |> run(if_script ++ script, opts)
  end

  # Run the else block (if present) of the provided script which was prepended by OP_IF or OP_NOTIF
  def run_else(stack, script, opts) do
    {_if_script, else_script, script} = parse_if(script)
    stack |> run(else_script ++ script, opts)
  end

  # Returns value: {if_block, else_block, remaining_script}
  defp parse_if(script), do: parse_if({[], []}, script, 0)

  # Found OP_ENDIF and we are not in the nested OP_IF, returning
  # To be faster we are appending to the beginning of the list when
  # collecting if and else blocks, so now it's time to reverse them
  defp parse_if(  {if_script, else_script}, [:OP_ENDIF | script], 0), do: {if_script |> Enum.reverse, else_script |> Enum.reverse, script}
  defp parse_else({if_script, else_script}, [:OP_ENDIF | script], 0), do: {if_script |> Enum.reverse, else_script |> Enum.reverse, script}

  # Found else, collect script for the else block
  defp parse_if({if_script, else_script}, [:OP_ELSE | script], 0), do: {if_script, else_script} |> parse_else(script, 0)

  # WHOA Multiple OP_ELSE statements are valid and execution inverts on each OP_ELSE encountered
  defp parse_else({if_script, else_script}, [:OP_ELSE | script], 0), do: {if_script, else_script} |> parse_if(script, 0)

  # Collect the else script part, change if_depth when encountering nested IFs
  defp parse_else({if_script, else_script}, [x | script], if_depth), do: {if_script, [x | else_script]} |> parse_else(script, if_depth + if_depth_change(x))

  # Collect the if script part, change if_depth when encountering nested IFs
  defp parse_if({if_script, else_script}, [x | script], if_depth), do: {[x | if_script], else_script} |> parse_if(script, if_depth + if_depth_change(x))

  defp if_depth_change(:OP_IF),    do:  1
  defp if_depth_change(:OP_NOTIF), do:  1
  defp if_depth_change(:OP_ENDIF), do: -1
  defp if_depth_change(_),         do:  0
end
