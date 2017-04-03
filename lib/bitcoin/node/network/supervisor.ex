defmodule Bitcoin.Node.Network.Supervisor do
  use Supervisor

  require Lager

  def start_link do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_) do
    Lager.info "Starting Node subsystems"
    modules = Bitcoin.Node.Network.modules()
    children = 
      [:addr, :discovery, :connection_manager]
      |> Enum.map(fn name -> modules[name] end)
      |> Enum.map(fn m -> worker(m, [%{modules: modules}]) end)

    children |> supervise(strategy: :one_for_one)
  end

end
