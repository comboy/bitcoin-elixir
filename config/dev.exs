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
