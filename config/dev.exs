use Mix.Config

# Check config.exs for available options documentation
# Uncomment the line below to start the node when the application is starting
# config :bitcoin, :node, []

# With this setting enabled when you encounter tx which doesn't pass validation,
# it will be automatically saved to test/data/auto and run as a test case when
# you run tx tests
# config :bitcoin, :util, save_as_test_case: true

config :logger,
  level: :info,
  truncate: :infinity

# Example configuration for running the node with postgres backend
# (database should already be created)
#
# config :bitcoin, :node,
#   modules: [
#     storage_engine: Bitcoin.Node.Storage.Engine.Postgres
# ]
#
# config :bitcoin, Bitcoin.Node.Storage.Engine.Postgres.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   database: "bitcoin_elixir_dev",
#   username: "bitcoin_elixir",
#   password: "bitcoin_elixir",
#   hostname: "localhost"

