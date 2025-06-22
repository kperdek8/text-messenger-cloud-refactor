defmodule TextMessengerBackend.ChatService.EventHandlers do
  require Logger

  def handle_chat_created(%{"user_id" => user_id, "chat_id" => chat_id}) do
    Logger.info("Handling chat.created (chat_id: #{chat_id} user_id: #{user_id}) ")
    TextMessengerBackend.ChatServiceWeb.Endpoint.broadcast("notifications:#{user_id}", "added_to_chat", %{chat_id: chat_id})
    :ok
  end
end
