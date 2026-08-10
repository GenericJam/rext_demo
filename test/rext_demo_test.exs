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

  test "typing in the counter's field mirrors keystroke by keystroke", %{
    counter: counter,
    mirror: mirror
  } do
    :ok = Window.dispatch(counter, "change", %{"tag" => "label_changed", "value" => "Tot"})
    :sys.get_state(mirror)
    assert Window.get_socket(mirror).assigns.label == "Tot"

    :ok = Window.dispatch(counter, "change", %{"tag" => "label_changed", "value" => "Total"})
    :sys.get_state(mirror)
    assert Window.get_socket(mirror).assigns.label == "Total"
  end

  test "submit clears the field from the server side", %{counter: counter, mirror: mirror} do
    :ok = Window.dispatch(counter, "change", %{"tag" => "label_changed", "value" => "scratch"})
    :ok = Window.dispatch(counter, "submit", %{"tag" => "label_cleared"})
    :sys.get_state(mirror)

    # The value pushed *down* to a focused field is the direction a naively
    # controlled input gets wrong, so it is worth pinning.
    assert Window.get_socket(counter).assigns.label == ""
    assert Window.get_socket(mirror).assigns.label == ""
  end

  # This app is the visual smoke test: one `mix rext.run` is supposed to put
  # every node type on screen at once. That only stays true if adding a
  # component to rext forces someone to put it here, so pin it.
  test "the counter window uses every node type rext ships", %{counter: counter} do
    used =
      counter
      |> Window.inspect()
      |> Map.fetch!(:tree)
      |> node_types()
      |> MapSet.new()

    missing = MapSet.difference(MapSet.new(Rext.Catalog.types()), used)

    assert MapSet.size(missing) == 0,
           "CounterWindow no longer demonstrates: #{inspect(MapSet.to_list(missing))}. " <>
             "Add them to the window so `mix rext.run` still shows every component."
  end

  defp node_types(%{type: type} = node) do
    [type | node |> Map.get(:children, []) |> Enum.flat_map(&node_types/1)]
  end
end
