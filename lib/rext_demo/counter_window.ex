defmodule RextDemo.CounterWindow do
  @moduledoc """
  Owns the count and the counter's name. Every change re-renders this window and
  is pushed to the `Mirror` window by a plain `send/2` — windows are processes,
  so cross-window updates are just messages.

  Also the visual smoke test for the component set: every node type rext has is
  on this window, so one `mix rext.run` exercises the lot.
  """
  use Rext.Window

  @impl true
  def mount(_params, socket) do
    socket =
      socket
      |> Rext.Socket.assign(:count, 0)
      |> Rext.Socket.assign(:label, "")
      |> notify_mirror()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    %{
      type: :column,
      props: %{spacing: :space_lg, padding: :space_xl, background: :background},
      children: [
        %{
          type: :box,
          props: %{
            background: :surface,
            padding: :space_lg,
            corner_radius: 12,
            fill_width: true,
            accessibility_label: "Counter readout"
          },
          children: [
            %{
              type: :text,
              props: %{
                text: "#{heading(assigns)}: #{assigns.count}",
                font_size: 34,
                text_color: :on_background
              },
              children: []
            }
          ]
        },
        %{type: :divider, props: %{color: :border}, children: []},
        # Type here and the mirror window follows you keystroke by keystroke.
        # Pressing Enter clears the field from the server side, which is the
        # round-trip that a naive controlled input gets wrong.
        %{
          type: :text_field,
          props: %{
            value: assigns.label,
            placeholder: "Name this counter, then press Enter…",
            on_change: :label_changed,
            on_submit: :label_cleared,
            accessibility_label: "Counter name"
          },
          children: []
        },
        %{type: :spacer, props: %{size: 8}, children: []},
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

  def handle_event("change", %{"tag" => "label_changed", "value" => value}, socket) do
    {:noreply, socket |> Rext.Socket.assign(:label, value) |> notify_mirror()}
  end

  # Clearing on submit is deliberate: it pushes a new value *down* to a field the
  # user is focused in, which is the direction that breaks when a backend binds
  # its text straight to the incoming value.
  def handle_event("submit", %{"tag" => "label_cleared"}, socket) do
    {:noreply, socket |> Rext.Socket.assign(:label, "") |> notify_mirror()}
  end

  defp heading(%{label: ""}), do: "Count"
  defp heading(%{label: label}), do: label

  # Send the current state to the mirror window if it's up. A no-op before the
  # mirror has started (e.g. during the counter's own mount at boot).
  defp notify_mirror(socket) do
    case Process.whereis(Rext.Window.via("mirror")) do
      nil -> :ok
      pid -> send(pid, {:sync, socket.assigns.count, socket.assigns.label})
    end

    socket
  end
end
