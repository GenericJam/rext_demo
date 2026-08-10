defmodule RextDemo.MirrorWindow do
  @moduledoc """
  Displays the count and name it receives from the `Counter` window. Holds no
  logic of its own — it just reacts to `{:sync, count, label}` messages and
  re-renders. A second window is a second process; keeping them in sync is
  message passing.
  """
  use Rext.Window

  @impl true
  def mount(_params, socket) do
    {:ok, socket |> Rext.Socket.assign(:count, 0) |> Rext.Socket.assign(:label, "")}
  end

  @impl true
  def render(assigns) do
    %{
      type: :column,
      props: %{spacing: :space_md, padding: :space_xl, background: :surface},
      children: [
        %{
          type: :text,
          props: %{text: "Mirror", font_size: 16, text_color: :muted},
          children: []
        },
        %{
          type: :text,
          props: %{text: "live count: #{assigns.count}", font_size: 28, text_color: :on_surface},
          children: []
        },
        %{type: :divider, props: %{color: :border}, children: []},
        %{
          type: :text,
          props: %{text: name(assigns), font_size: 16, text_color: :muted},
          children: []
        }
      ]
    }
  end

  @impl true
  def handle_info({:sync, count, label}, socket) do
    {:noreply, socket |> Rext.Socket.assign(:count, count) |> Rext.Socket.assign(:label, label)}
  end

  defp name(%{label: ""}), do: "(unnamed)"
  defp name(%{label: label}), do: "name: #{label}"
end
