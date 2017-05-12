defmodule Bitcoin.Node.Storage.Engine.Postgres.Models.Tx do
  use Ecto.Schema

  schema "tx" do
    field :hash, :binary
    field :version, :integer
    field :lock_time, :integer
  end
end
