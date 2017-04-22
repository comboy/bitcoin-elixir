defmodule Bitcoin do
  use Application

  # Not sure if that's the best place for this tye def, feel free to rename and move
  @type t_hash :: <<_::32, _::_*8>>
  @type t_hex_hash :: <<_::64, _::_*8>>


  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Start node only if :bitcoin,:node config section is present
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

