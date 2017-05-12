defmodule Bitcoin.Node.Storage.Engine.Postgres.Models.Block do
  use Ecto.Schema

  schema "block" do
    field :version, :integer
    field :previous_block, :binary
    field :merkle_root, :binary
    field :timestamp, :integer
    field :bits, :integer
    field :nonce, :integer
    field :transactions, {:array, :binary}

    field :hash, :binary
    field :height, :integer
    field :main_chain, :boolean
  end

end
