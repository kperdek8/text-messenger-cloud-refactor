defmodule TextMessengerBackend.NotificationService.EventHandlers do
  require Logger
  alias TextMessengerBackend.NotificationService.EmailNotifier

  def handle_user_added_to_chat(%{"id" => id, "chat_id" => chat_id}) do
    Logger.debug("Handling user.added_to_chat (user #{id} -> chat #{chat_id}")
    EmailNotifier.send_email("You have been added to new chat", "You have been added to new chat (id #{chat_id}).")
  end
end
