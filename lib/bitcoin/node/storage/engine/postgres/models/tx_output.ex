defmodule Bitcoin.Node.Storage.Engine.Postgres.Models.TxOutput do
  use Ecto.Schema

  schema "tx_output" do
    field :tx_hash, :binary
    field :index, :integer
    field :value, :integer
    field :pk_script, :binary
  end
end
