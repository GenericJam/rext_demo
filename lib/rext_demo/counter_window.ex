defmodule RextDemo.CounterWindow do
  @moduledoc """
  Owns the count. Every change re-renders this window and is pushed to the
  `Mirror` window by a plain `send/2` — windows are processes, so cross-window
  updates are just messages.
  """
  use Rext.Window

  @impl true
  def mount(_params, socket) do
    {:ok, socket |> Rext.Socket.assign(:count, 0) |> notify_mirror()}
  end

  @impl true
  def render(assigns) do
    %{
      type: :column,
      props: %{spacing: :space_lg, padding: :space_xl, background: :background},
      children: [
        %{
          type: :text,
          props: %{text: "Count: #{assigns.count}", font_size: 34, text_color: :on_background},
          children: []
        },
        %{
          type: :row,
          props: %{spacing: :space_md},
          children: [
            %{
              type: :button,
              props: %{text: "−", on_click: :dec, background: :surface},
              children: []
            },
            %{
              type: :button,
              props: %{text: "Reset", on_click: :reset, background: :surface},
              children: []
            },
            %{
              type: :button,
              props: %{text: "+", on_click: :inc, background: :primary},
              children: []
            }
          ]
        }
      ]
    }
  end

  @impl true
  def handle_event("click", %{"tag" => tag}, socket) do
    count =
      case tag do
        "inc" -> socket.assigns.count + 1
        "dec" -> socket.assigns.count - 1
        "reset" -> 0
      end

    {:noreply, socket |> Rext.Socket.assign(:count, count) |> notify_mirror()}
  end

  # Send the current count to the mirror window if it's up. A no-op before the
  # mirror has started (e.g. during the counter's own mount at boot).
  defp notify_mirror(socket) do
    case Process.whereis(Rext.Window.via("mirror")) do
      nil -> :ok
      pid -> send(pid, {:sync_count, socket.assigns.count})
    end

    socket
  end
end
