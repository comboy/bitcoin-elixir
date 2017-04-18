defmodule Bitcoin.Mixfile do
  use Mix.Project

  def project do
    [app: :bitcoin,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Docs
     name: "bitcoin-elixir",
     source_url: "https://github.com/comboy/bitcoin-elixir",
     homepage_url: "https://github.com/comboy/bitcoin-elixir",
     docs: [main: "README",
          extras: ["README.md"]]
   ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: { Bitcoin, [] },
     applications: [
       :logger
       ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
     # Socket acceptor pool
     {:reagent, "~> 0.1.5"},
     # JSON library, used to decode test cases
     {:poison, "~> 3.0", only: :test},
     # Docs generator
     {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
end
