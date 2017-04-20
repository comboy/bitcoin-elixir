defmodule Bitcoin.Const do
 
  defmacro __using__(_opts) do
    quote do

      # Configurable network name e.g. bitcoin, testnet
      @network Application.get_env(:bitcoin, :network) || :bitcoin

      # Common chain params

      # Number of base units in one coin
      @coin 100_000_000

      # Halving frequency (in number of blocks)
      @subsidy_halving_interval 210_000

      # Block reward before the first halving
      @base_subsidy_value 50*@coin

      # Network specific chain params
      case @network do
        :bitcoin -> use Bitcoin.ChainParams.Bitcoin
        :testnet -> use Bitcoin.ChainParams.Testnet
      end

    end
  end

end
