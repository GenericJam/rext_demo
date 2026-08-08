defmodule RextDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    with {:ok, pid} <-
           Supervisor.start_link([], strategy: :one_for_one, name: RextDemo.Supervisor) do
      Rext.boot(RextDemo)
      {:ok, pid}
    end
  end
end

defmodule RextDemo do
  use Rext.App

  @impl true
  def windows do
    [{RextDemo.CounterWindow, id: "main", title: "RextDemo", size: {420, 300}}]
  end
end
