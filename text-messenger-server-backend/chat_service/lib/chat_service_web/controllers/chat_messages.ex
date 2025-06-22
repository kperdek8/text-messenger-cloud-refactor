defmodule TextMessengerBackend.ChatServiceWeb.ChatMessagesController do
  use TextMessengerBackend.ChatServiceWeb, :controller

  alias TextMessengerBackend.ChatService.Chats

  def fetch_messages(conn, %{"id" => chat_id}) do
    user_id = conn.assigns.user_id
    if Chats.is_user_member_of_chat?(user_id, chat_id) do
      {:ok, messages} = Chats.get_chat_messages(chat_id)
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{messages: messages}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(403, Jason.encode!(%{error: "You are not member of this chat"}))
    end
  end

  def fetch_messages(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{error: "Chat ID not provided"}))
  end
end
