defmodule RextDemo.MirrorWindow do
  @moduledoc """
  Displays the count it receives from the `Counter` window. Holds no logic of
  its own — it just reacts to `{:sync_count, n}` messages and re-renders. A
  second window is a second process; keeping them in sync is message passing.
  """
  use Rext.Window

  @impl true
  def mount(_params, socket), do: {:ok, Rext.Socket.assign(socket, :count, 0)}

  @impl true
  def render(assigns) do
    %{
      type: :column,
      props: %{gap: :space_md, padding: :space_xl, background: :surface},
      children: [
        %{
          type: :text,
          props: %{text: "Mirror", size: 16, color: :muted},
          children: []
        },
        %{
          type: :text,
          props: %{text: "live count: #{assigns.count}", size: 28, color: :on_surface},
          children: []
        }
      ]
    }
  end

  @impl true
  def handle_info({:sync_count, count}, socket) do
    {:noreply, Rext.Socket.assign(socket, :count, count)}
  end
end
