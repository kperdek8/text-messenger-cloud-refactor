defmodule TextMessengerBackend.ChatService.Chats do
  alias TextMessengerBackend.ChatService.Repo
  alias TextMessengerBackend.ChatService.Chats.{Chat, ChatUser, ChatMessage}
  alias TextMessenger.Protobuf

  import Ecto.Query

  @doc """
  Creates a new chat with the specified name.
  """
  def create_chat(name) do
    %Chat{}
    |> Chat.changeset(%{name: name})
    |> Repo.insert!()
  end

  @doc """
  Fetches a chat by ID and converts it to Protobuf format.
  """
  def get_chat(id) do
    chat =
      from(c in Chat, where: c.id == ^id, select: c)
      |> Repo.one()

    case chat do
      nil -> {:error, "Chat not found"}
      chat -> {:ok, chat}
    end
  end

  @doc """
  Fetches all chats available to user and converts it to Protobuf format.
  """
  def get_chats(user_id) do
    chats =
      from(c in Chat,
        join: cu in ChatUser,
        on: cu.chat_id == c.id,
        where: cu.user_id == ^user_id,
        select: c,
        order_by: [asc: c.name]
      )
      |> Repo.all()

    {:ok, chats}
  end

  @doc """
  Adds a user to a chat.
  """
  def add_user_to_chat(chat_id, user_id) do
    case Repo.get_by(ChatUser, chat_id: chat_id, user_id: user_id) do
      nil ->
        %ChatUser{}
        |> ChatUser.changeset(%{chat_id: chat_id, user_id: user_id})
        |> Repo.insert()

      _ ->
        {:error, :already_member}
    end
  end

  @doc """
  Removes a user from a chat by deleting the entry in the ChatUser join table.
  """
  def remove_user_from_chat(chat_id, user_id) do
    query = from cu in ChatUser,
            where: cu.chat_id == ^chat_id and cu.user_id == ^user_id

    case Repo.delete_all(query) do
      {0, _} -> :not_member
      {1, _} -> :ok
      {count, _} when count > 1 -> {:error, "Multiple associations found, which shouldn't happen"}
    end
  end

  @doc """
  Fetches users in a specific chat and returns them in Protobuf format.
  """
  def get_chat_members(chat_id) do
    users =
      from(u in ChatUser,
        where: u.chat_id == ^chat_id,
        select: u.user_id
      )
      |> Repo.all()

    {:ok, users}
  end

  @doc """
  Fetches messages for a specific chat. Messages are returned in Protobuf format.
  """
  def get_chat_messages(chat_id) do
    messages =
      from(m in ChatMessage,
        where: m.chat_id == ^chat_id,
        order_by: [desc: m.timestamp],
        select: m
      )
      |> Repo.all()

    {:ok, messages}
  end

  @doc """
  Inserts a new message into a specified chat.
  """
  def insert_chat_message(chat_id, user_id, content) do
    %ChatMessage{}
    |> ChatMessage.changeset(%{
      chat_id: chat_id,
      user_id: user_id,
      content: content,
      timestamp: DateTime.utc_now(),
    })
    |> Repo.insert()
  end

  @doc """
  Verifies if user is member of specific chat.
  """
  def is_user_member_of_chat?(user_id, chat_id) do
    from(cu in ChatUser,
      where: cu.chat_id == ^chat_id and cu.user_id == ^user_id,
      select: cu.user_id
    )
    |> Repo.exists?()
  end

  # Conversion Functions

  defp to_protobuf_users(users) do
    %Protobuf.Users{
      users: users
    }
  end

  defp to_protobuf_chat(%Chat{id: id, name: name}) do
    {:ok, %Protobuf.Users{users: users}} = get_chat_members(id)
    %Protobuf.Chat{
      id: Ecto.UUID.cast!(id),
      name: name,
      user_ids: users
    }
  end

  defp to_protobuf_chats(chats) do
    %Protobuf.Chats{
      chats: Enum.map(chats, &to_protobuf_chat/1)
    }
  end

  defp to_protobuf_message(%ChatMessage{id: id, user_id: user_id, chat_id: chat_id, content: content, timestamp: timestamp}) do
    %Protobuf.ChatMessage{
      id: Ecto.UUID.cast!(id),
      user_id: user_id,
      chat_id: Ecto.UUID.cast!(chat_id),
      content: content,
      timestamp: DateTime.to_string(timestamp),
    }
  end

  defp to_protobuf_messages(messages) do
    %Protobuf.ChatMessages{
      messages: Enum.map(messages, &to_protobuf_message/1)
    }
  end
end
