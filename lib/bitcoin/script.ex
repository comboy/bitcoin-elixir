defmodule Bitcoin.Script do

  @moduledoc """
  Bitcoin Script.

  Bitcoin uses a scripting system for transactions. Forth-like, Script is simple, stack-based
  and processed from left to right. It is purposefully not Turing-complete, with no loops.

  This module contains functions to oparet on scripts. The actual implementation of the Script
  engine can be found in `Bitcoin.Script.Interpreter`

  Common pattern of `opts` is passed to verification and run functions. They set up the context
  for script verification. Here are the opts used:
  * `tx` - `Bitcoin.Protocol.Messages.Tx` in which the script is present
  * `input_number` - input number of that transaction (needed for sighash)
  * `sub_script` - also used for sighash, (often equal to pk_script)
  * `flags` - script validation flags, see below

  Flags are in the format of hash e.g. %{p2sh: true, dersig: true}. The reason for using that
  instead of a simple list is ability to do function matching.
  """

  # Script.Serialization handles parsing the script from a binary into a list with opcodes as symbols.
  # Script.Control implements parsing OP_IF
  # Script.Number handles parsing and serializing script integers (CStriptNum)

  # TODO block sigop limit (MAX_BLOCK_SIGOPS = MAX_BLOCK_SIZE/50), so we need to be abel to export that count
  # TODO verify signature encoding https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki
  use Bitcoin.Script.P2SH

  alias Bitcoin.Script.Serialization
  alias Bitcoin.Script.Interpreter

  @doc """
  Parse binary script into a form consumable by the interpreter (ops list). Parsed script looks like this:

      [:OP_10, :OP_10, :OP_ADD, <<20>>, :OP_EQUAL]
  """
  defdelegate parse(binary), to: Serialization

  @doc """
  Represent parsed script (list of :OP_CODES and binary data), in it's original binary form.
  """
  defdelegate to_binary(script), to: Serialization

  @doc """
  Returns string representation of the provided parsed script in the same form as bitcoind decodescript command
  """
  defdelegate to_string(script), to: Serialization

  @doc """
  Parse script from the string in a format that is outputed by bitcoid.

  E.g. "2 OP_IF 0 OP_ELSE 1 OP_ENDIF"
  """
  defdelegate parse_string(string), to: Serialization

  @doc """
  Parse script from a strig form familiar from test cases.

  E.g. "128 SIZE 2 EQUAL"

  Binaries appear in the 0x form or literaly in single quotes.
  """
  defdelegate parse_string2(string), to: Serialization

  @doc """
  Run the provided script. Returns the resulting stack or {:error, reason} tuple.
  """
  @spec run(list | binary, map) :: list | {:error, term}
  def run(script, opts \\ %{})

  def run(binary, opts) when is_binary(binary), do: binary |> parse |> run(opts)
  defdelegate run(script, opts), to: Interpreter
  defdelegate run(stack, script, opts), to: Interpreter

  # The reason for this function is that we need to parse sig script and pk separately.
  # Otherwise sig script could do some nasty stuff with malformed PUSHDATA
  # Then we have to run it separately

  # default opts are done this weird way because additional function cases come from uses above (to avoid warnings)
  def verify_sig_pk(sig_bin, pk_bin), do: verify_sig_pk(sig_bin, pk_bin, %{})
  def verify_sig_pk(sig_bin, pk_bin, opts) when is_binary(sig_bin) and is_binary(pk_bin), do: verify_sig_pk(sig_bin |> parse, pk_bin |> parse, opts)
  def verify_sig_pk(sig_script, pk_script, opts) do
    try do
      sig_script
      |> run(opts)
      # TODO this validate function is so out of place
      |> run(pk_script |> Interpreter.validate, opts)
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
  def cast_to_bool({:error, _}), do: false
  def cast_to_bool([]), do: false
  def cast_to_bool([x | _]), do: Interpreter.bool(x)


end
