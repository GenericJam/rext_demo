defmodule RextDemoTest do
  use ExUnit.Case, async: false

  alias Rext.Window

  # The proof: two windows are two processes, and driving one keeps the other
  # in sync purely by message passing — no shared state, no renderer needed.

  # `RextDemo.Application.start/2` calls `Rext.boot/1`, so the app's windows are
  # already up (and hold the registered names) before any test runs. Replace
  # them with test-owned processes so each test starts from count 0.
  setup do
    mirror = restart_window(RextDemo.MirrorWindow, "mirror")
    counter = restart_window(RextDemo.CounterWindow, "main")
    %{counter: counter, mirror: mirror}
  end

  defp restart_window(module, id) do
    case Process.whereis(Window.via(id)) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(Rext.WindowSupervisor, pid)
    end

    {:ok, pid} = Window.start_link(module, %{}, id: id)
    pid
  end

  test "app declares both windows" do
    ids = for {_mod, opts} <- RextDemo.windows(), do: opts[:id]
    assert "main" in ids
    assert "mirror" in ids
  end

  test "clicking the counter syncs the mirror window", %{counter: counter, mirror: mirror} do
    :ok = Window.dispatch(counter, "click", %{"tag" => "inc"})
    :ok = Window.dispatch(counter, "click", %{"tag" => "inc"})
    :sys.get_state(mirror)
    assert Window.get_socket(counter).assigns.count == 2
    assert Window.get_socket(mirror).assigns.count == 2

    :ok = Window.dispatch(counter, "click", %{"tag" => "reset"})
    :sys.get_state(mirror)
    assert Window.get_socket(counter).assigns.count == 0
    assert Window.get_socket(mirror).assigns.count == 0
  end

  test "decrement goes negative and still mirrors", %{counter: counter, mirror: mirror} do
    :ok = Window.dispatch(counter, "click", %{"tag" => "dec"})
    :sys.get_state(mirror)
    assert Window.get_socket(mirror).assigns.count == -1
  end
end
