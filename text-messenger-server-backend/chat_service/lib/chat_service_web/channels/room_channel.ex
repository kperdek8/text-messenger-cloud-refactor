defmodule TextMessengerBackend.ChatServiceWeb.ChatChannel do
  use Phoenix.Channel

  alias TextMessengerBackend.ChatService.Chats
  alias TextMessengerBackend.ChatService.Chats.ChatMessage

  require Logger

  def join("chat:" <> chat_id, _params, socket) do
    user_id = socket.assigns.user_id
    if Chats.is_user_member_of_chat?(user_id, chat_id) do
      socket = assign(socket, :chat_id, chat_id)
      {:ok, socket}
    else
      {:error, "You are not member of this chat"}
    end
  end

  def handle_in("new_message", %{"content" => encoded_content}, socket) do
    chat_id = socket.assigns.chat_id
    user_id = socket.assigns.user_id

    {:ok, content} = Base.decode64(encoded_content)

    case Chats.insert_chat_message(chat_id, user_id, content) do
      {:ok, %ChatMessage{id: message_id}} ->
        broadcast!(socket, "new_message", %{
          message_id: message_id,
          content: encoded_content,
          user_id: user_id,
        })

        {:reply, {:ok, %{message: "message_received"}}, socket}

      {:error, reason} ->
        Logger.error("Failed to insert chat message: #{inspect(reason)}")
        {:reply, {:error, %{error: "Failed to send message"}}, socket}
    end
  end

  # Ignore incorrect payload
  def handle_in("new_message", payload, socket) do
    Logger.debug("Incorrect payload in socket message `new_message`: #{inspect(payload)}}")
    {:noreply, socket}
  end

  def handle_in("add_user", %{"user_id" => user_id}, socket) do
    case Chats.add_user_to_chat(socket.assigns.chat_id, user_id) do
      {:ok, _chatuser} ->
        TextMessengerBackend.ChatServiceWeb.Endpoint.broadcast("notifications:#{user_id}", "added_to_chat", %{chat_id: socket.assigns.chat_id})
        broadcast_from!(socket, "add_user", %{user_id: user_id})

        {:noreply, socket}

      {:error, :already_member} -> {:noreply, socket}
      {:error, :user_not_found} -> {:noreply, socket}
    end
  end

  def handle_in("add_user", payload, socket) do
    Logger.debug("Incorrect payload in socket message `add_user`: #{inspect(payload)}}")
    {:noreply, socket}
  end

  def handle_in("kick_user", %{"user_id" => user_id}, socket) do
    case Chats.remove_user_from_chat(socket.assigns.chat_id, user_id) do
      :ok ->
        TextMessengerBackend.ChatServiceWeb.Endpoint.broadcast("notifications:#{user_id}", "removed_from_chat", %{chat_id: socket.assigns.chat_id})
        broadcast_from!(socket, "kick_user", %{"user_id" => user_id})
        {:noreply, socket}
      :not_member ->
        {:noreply, socket}
      {:error, reason} ->
        IO.inspect(reason, label: "Unexpected behaviour when removing user")
        {:noreply, socket}
    end
  end

  def handle_in("kick_user", payload, socket) do
    Logger.debug("Incorrect payload in socket message `kick_user`: #{inspect(payload)}}")
    {:noreply, socket}
  end

  intercept ["kick_user"]

  def handle_out("kick_user", %{"user_id" => user_id} = payload, socket) do
    if socket.assigns.user_id == user_id do
      # Unsubscribe the kicked user from the topic
      {:stop, :normal, socket}
    else
      # Forward the message to other clients
      push(socket, "kick_user", payload)
      {:noreply, socket}
    end
  end
end
