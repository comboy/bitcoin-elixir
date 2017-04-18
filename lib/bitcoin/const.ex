defmodule Bitcoin.Const do
 
  defmacro __using__(_opts) do
    quote do
      # TODO use different module depending on the network selected in config

      use Bitcoin.ChainParams.Bitcoin
    end
  end

end
