defmodule Bitcoin do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Start node only if :bitcoin,:node config section is present
    # TODO this is not great, because when using Bitcon-Ex as a lib,
    # there must a way to overwrite our dev default (which is node enabled)
    children = case Application.fetch_env(:bitcoin, :node) do
      :error ->
         []
      {:ok, _node_config} ->
         [ supervisor(Bitcoin.Node.Supervisor, []) ]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bitcoin.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

