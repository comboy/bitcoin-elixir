defmodule Bitcoin.Script.Macros do

  defmacro op(op, stack_clause, do: stack_expression) when is_atom(op) do
    quote do
      def run(unquote(stack_clause), [unquote(op) | script], opts) do
        (unquote(stack_expression)) |> run(script, opts)
      end
    end
  end

end
