defmodule RextDemo.CounterWindow do
  use Rext.Window

  @impl true
  def mount(_params, socket), do: {:ok, Rext.Socket.assign(socket, :count, 0)}

  @impl true
  def render(assigns) do
    %{
      type: :column,
      props: %{gap: :space_lg, padding: :space_xl, background: :background},
      children: [
        %{type: :text, props: %{text: "Count: #{assigns.count}", size: 34, color: :on_background}, children: []},
        %{type: :button, props: %{label: "Increment", on_click: :inc, color: :primary}, children: []}
      ]
    }
  end

  @impl true
  def handle_event("click", %{"tag" => "inc"}, socket) do
    {:noreply, Rext.Socket.update(socket, :count, &(&1 + 1))}
  end
end
