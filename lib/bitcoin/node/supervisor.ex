defmodule Bitcoin.Node.Supervisor do
  use Supervisor

  require Lager

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Lager.info "Starting Node subsystems"
    children = [
      worker(Bitcoin.Node, []),
      supervisor(Bitcoin.Node.Network.Supervisor, [])
    ]

    children |> supervise(strategy: :one_for_one)
  end

end
