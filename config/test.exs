use Mix.Config

# Check config.exs for available options documentation

config :logger,
  level: :error

# Example configuration for testing postgres backend:
#
# config :bitcoin, Bitcoin.Node.Storage.Engine.Postgres.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   pool: Ecto.Adapters.SQL.Sandbox,
#   database: "bitcoin_elixir_test",
#   username: "bitcoin_elixir",
#   password: "bitcoin_elixir",
#   hostname: "localhost"

config :logger, level: :warn
