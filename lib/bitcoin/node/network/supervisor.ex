defmodule Bitcoin.Node.Network.Supervisor do

  use Bitcoin.Common
  use Supervisor

  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_) do
    Logger.info "Starting Node subsystems"

    [
      @modules[:addr],
      @modules[:discovery],
      @modules[:connection_manager],
      # Storage module is an abstraction on top of the actual storage engine so it doesn't have to be dynamic
      Bitcoin.Node.Storage,
      @modules[:inventory]
    ]
    |> Enum.map(fn m -> worker(m, []) end)
    |> supervise(strategy: :one_for_one)
  end

end
