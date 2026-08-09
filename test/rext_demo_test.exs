defmodule RextDemoTest do
  use ExUnit.Case, async: false

  alias Rext.Window

  # The proof: two windows are two processes, and driving one keeps the other
  # in sync purely by message passing — no shared state, no renderer needed.

  # `RextDemo.Application.start/2` calls `Rext.boot/1`, so the app's windows are
  # already up (and hold the registered names) before any test runs. Replace
  # them with test-owned processes so each test starts from count 0.
  #
  # Mirror first: the counter notifies the mirror during its own mount, and we
  # want that first sync to land rather than be a no-op.
  setup do
    mirror = restart_window(RextDemo.MirrorWindow, "mirror")
    counter = restart_window(RextDemo.CounterWindow, "main")
    %{counter: counter, mirror: mirror}
  end

  # start_supervised! rather than start_link: ExUnit guarantees a supervised
  # child is down before the next test starts, where a merely *linked* window is
  # not — a `:normal` exit from the test process doesn't kill a non-trapping
  # child. Without that guarantee the survivor holds the registered name and the
  # next setup dies with :already_started (see rext's bridge_test for the same
  # bug caught in CI).
  defp restart_window(module, id) do
    free_name(Window.via(id))

    start_supervised!(%{
      id: {:window, id},
      start: {Window, :start_link, [module, %{}, [id: id]]},
      restart: :temporary
    })
  end

  # Free a registered window name and wait for the process to actually be gone.
  # Two cases: the app's own windows are `Rext.WindowSupervisor` children, but a
  # leftover from an earlier test is not — `terminate_child` reports
  # `:not_found` for those, so they have to be stopped directly.
  defp free_name(name) do
    case Process.whereis(name) do
      nil ->
        :ok

      pid ->
        ref = Process.monitor(pid)

        case DynamicSupervisor.terminate_child(Rext.WindowSupervisor, pid) do
          :ok -> :ok
          {:error, :not_found} -> Process.exit(pid, :kill)
        end

        receive do
          {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
        after
          1_000 -> flunk("window #{inspect(name)} would not stop")
        end
    end
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
