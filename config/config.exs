# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Ecto raises in case adapter config is missing even if we don't
# start :ecto app and don't use it at all, so here goes:
config :bitcoin, ecto_repos: [Bitcoin.Node.Storage.Engine.Postgres.Repo]
config :bitcoin, Bitcoin.Node.Storage.Engine.Postgres.Repo, adapter: Ecto.Adapters.Postgres


# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
# Bitcoin general options
#
# Choose network, :testnet or :bitcoin
# config :bitcoin, :network, :bitcoin
#
# Bitcoin node configuration options.
#
# Node will be started automatically when the app is started if
# any bitcoin.node config is present, so you can run it with default
# options by just uncommenting the following line:
#
# config :bitcoin, :node, []
#
# Available configuration options are documented below, You don't have to
# set all of them, for options not present, defaults are used
#
# config :bitcoin, :node [
#   # IP on which p2p connections will be accepted
#   listen_ip: '0.0.0.0',
#
#   # Port for accepting p2p connections
#   listen_port: @default_listen_port,
#
#   # Maximum number of connections that the node should try to keep open
#   max_connections: 8,
#
#   # User agent that node will be sending in the VErsION packet
#   user_agent: "/bitcoin-elixir:0.0.0/",
#
#   # Directory where known addrs and blockchain are kept
#   data_directory: Path.expand("~/.bitcoin-elixir/#{@network}"),
# ]
#
# Example of using Postgres storage backend:
#
# config :bitcoin, Bitcoin.Node.Storage.Engine.Postgres.Repo,
#  adapter: Ecto.Adapters.Postgres,
#  database: "bitcoin_elixir_dev",
#  username: "bitcoin_elixir",
#  password: "bitcoin_elixir",
#  hostname: "localhost"
#
# config :bitcoin, :node,
#   modules: [storage_engine: Bitcoin.Node.Storage.Engine.Postgres]


import_config "#{Mix.env}.exs"

