defmodule RectDemoTest do
  use ExUnit.Case, async: false

  alias Rect.Window

  # The proof: two windows are two processes, and driving one keeps the other
  # in sync purely by message passing — no shared state, no renderer needed.

  setup do
    {:ok, mirror} = Window.start_link(RectDemo.MirrorWindow, %{}, id: "mirror")
    {:ok, counter} = Window.start_link(RectDemo.CounterWindow, %{}, id: "main")
    %{counter: counter, mirror: mirror}
  end

  test "app declares both windows" do
    ids = for {_mod, opts} <- RectDemo.windows(), do: opts[:id]
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
