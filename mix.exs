defmodule Bitcoin.Mixfile do
  use Mix.Project

  def project do
    [app: :bitcoin,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: { Bitcoin.Node, [] },
     applications: [
       :exlager
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
    [{:reagent, "~> 0.1.5"},
     {:exlager, git: "https://github.com/khia/exlager.git", branch: "master"}
    ]
  end
end
