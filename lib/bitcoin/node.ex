defmodule Bitcoin.Node do
  use Application

  defmodule Subsystems do
    use Supervisor

    def start_link do
      Supervisor.start_link(__MODULE__, :ok, [])
    end

    @peer_subsystem_name Bitcoin.Node.Peers

    def init(:ok) do
      children = [
        supervisor(@peer_subsystem_name, [[name: @peer_subsystem_name]])
      ]

      supervise([], strategy: :one_for_one)
    end

  end

  def start(_type, _args) do
    Subsystems.start_link()
  end
end