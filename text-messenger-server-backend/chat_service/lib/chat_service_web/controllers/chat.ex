defmodule TextMessengerBackend.ChatServiceWeb.ChatController do
  use TextMessengerBackend.ChatServiceWeb, :controller
  alias TextMessengerBackend.ChatService.Chats

  def fetch_chats(conn, _params) do
    user_id = conn.assigns.user_id
    {:ok, chat_list} = Chats.get_chats(user_id)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{chats: chat_list}))
  end

  def fetch_chat(conn, %{"id" => id}) do
    case Ecto.UUID.cast(id) do
      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid UUID format"}))

      {:ok, valid_uuid} ->
        user_id = conn.assigns.user_id
        if Chats.is_user_member_of_chat?(user_id, valid_uuid) do
          case Chats.get_chat(valid_uuid) do
            {:ok, chat} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(200, Jason.encode!(chat))
            {:error, message} ->
              conn
              |> send_resp(404, Jason.encode!(%{error: message}))
          end
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "You are not member of this chat"}))
        end
    end
  end

  def fetch_chat(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{error: "Chat ID not provided"}))
  end

  def create_chat(conn, %{"name" => name}) do
    user_id = conn.assigns.user_id
    chat = Chats.create_chat(name)
    Chats.add_user_to_chat(chat.id, user_id)
    TextMessengerBackend.ChatServiceWeb.Endpoint.broadcast("notifications:#{user_id}", "added_to_chat", %{chat_id: chat.id})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(chat))
  end

  def fetch_chat_members(conn, %{"id" => chat_id}) do
    user_id = conn.assigns.user_id
    if Chats.is_user_member_of_chat?(user_id, chat_id) do
      {:ok, users} = Chats.get_chat_members(chat_id)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{users: users}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(403, Jason.encode!(%{error: "You are not member of this chat"}))
    end
  end
end
