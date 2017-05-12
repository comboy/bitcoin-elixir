defmodule Bitcoin.Mixfile do
  use Mix.Project

  def project do
    [app: :bitcoin,
     version: "0.0.2",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package(),
     dialyzer: [plt_add_deps: true],

     # Docs
     name: "bitcoin-elixir",
     source_url: "https://github.com/comboy/bitcoin-elixir",
     homepage_url: "https://github.com/comboy/bitcoin-elixir",
     docs: [main: "readme",
          extras: ["README.md"]]
   ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: { Bitcoin, [] },
     applications: [:logger]
     # :ecto and :postgrex apps are started by the Postgres storage engine when necessary
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
     # using github version instead of hex because of the recent dializer fix which is not yet in hex
     {:reagent, github: "meh/reagent"},

     # Binary handling
     {:binary, "0.0.4"},

     # JSON library, used to decode test cases
     {:poison, "~> 3.0", only: [:dev, :test]},

     # Docs generator
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},

     # Static type analysis
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},

     # bitcoin/libsecpy256k1 NIF
     {:libsecp256k1, [github: "mbrix/libsecp256k1", manager: :rebar, optional: true]},

     # Node postgres storage engine
     {:ecto, github: "elixir-ecto/ecto", optional: true}, # can be switched to hex once 2.2 is out
     {:postgrex, "~> 0.13", optional: true}
    ]
  end

  defp description do
    "Bitcoin tools and full node implementation"
  end

  defp package do
    [
      name: :bitcoin,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["comboy"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/comboy/bitcoin-elixir"}
    ]
  end
end
