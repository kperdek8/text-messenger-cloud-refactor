defmodule TextMessengerBackend.ChatService.Chats.ChatUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "chat_users" do
    belongs_to(:chat, TextMessengerBackend.ChatService.Chats.Chat, type: :binary_id)
    field(:user_id, :string) # Cognito UUID
  end

  @doc false
  def changeset(chat_user, attrs) do
    chat_user
    |> cast(attrs, [:chat_id, :user_id])
    |> validate_required([:chat_id, :user_id])
  end
end
