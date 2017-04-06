defmodule Bitcoin.Script.Macros do

  defmacro op(op, {:when, _, [stack_clause, when_clause]}, do: stack_expression) when is_atom(op) do
    stack_clause |> IO.inspect
    quote do
      def run(unquote(stack_clause), [unquote(op) | script], opts) when unquote(when_clause) do
        (unquote(stack_expression)) |> run(script, opts)
      end
    end
  end

  defmacro op(op, stack_clause, do: stack_expression) when is_atom(op) do
    quote do
      def run(unquote(stack_clause), [unquote(op) | script], opts) do
        (unquote(stack_expression)) |> run(script, opts)
      end
    end
  end

  defmacro op(op, stack_clause, do: stack_expression) when is_atom(op) do
    quote do
      def run(unquote(stack_clause), [unquote(op) | script], opts) do
        (unquote(stack_expression)) |> run(script, opts)
      end
    end
  end

  defmacro op_alias(op, list) when is_atom(op) and is_list(list) do
    quote do
      def run(stack, [unquote(op) | script], opts) do
        stack |> run(unquote(list) ++ script, opts)
      end
    end
  end

end
