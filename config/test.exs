use Mix.Config


# TODO Logger.supresses unused variable warnings when it removes parts of the AST
# Unfortunately Lager doesn't do that. Would be nice to find some workaround.

config :exlager,
  level: :error

