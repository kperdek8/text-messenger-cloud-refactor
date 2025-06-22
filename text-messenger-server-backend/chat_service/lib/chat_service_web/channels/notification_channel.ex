defmodule TextMessengerBackend.ChatServiceWeb.NotificationChannel do
  use Phoenix.Channel
  require Logger

  def join("notifications:" <> user_id, _params, socket) do
    if user_id == socket.assigns.user_id do
      {:ok, socket}
    else
      {:error, "You are not this user"}
    end
  end

  def handle_info(%{event: "added_to_chat", payload: payload}, socket) do
    Logger.info("Sending added_to_chat in channel #{socket.topic} with payload #{inspect(payload)}")
    push(socket, "added_to_chat", payload)
    {:noreply, socket}
  end

  def handle_info(%{event: "removed_from_chat", payload: payload}, socket) do
    Logger.info("Sending removed_from_chat in channel #{socket.topic} with payload #{inspect(payload)}")
    push(socket, "added_to_chat", payload)
    {:noreply, socket}
  end
end
