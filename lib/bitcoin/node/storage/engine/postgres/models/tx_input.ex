defmodule Bitcoin.Node.Storage.Engine.Postgres.Models.TxInput do
  use Ecto.Schema

  schema "tx_input" do
    field :tx_hash, :binary
    field :prevout_hash, :binary
    field :prevout_index, :integer
    field :sig_script, :binary
    field :sequence, :integer
    field :index, :integer
  end

end
