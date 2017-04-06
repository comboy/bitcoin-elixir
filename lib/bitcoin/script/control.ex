defmodule Bitcoin.Script.Control do

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
  def extract_if(script) do
    {if_script, _else_script, script} = parse_if(script)
    if_script ++ script
  end

  # Run the else block (if present) of the provided script which was prepended by OP_IF or OP_NOTIF
  def extract_else(script) do
    {_if_script, else_script, script} = parse_if(script)
    else_script ++ script
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
