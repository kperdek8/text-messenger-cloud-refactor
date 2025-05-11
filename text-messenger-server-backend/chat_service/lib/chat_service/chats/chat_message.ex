defmodule TextMessengerBackend.ChatService.Chats.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "chat_messages" do
    field(:user_id, :string)
    belongs_to(:chat, TextMessengerBackend.ChatService.Chats.Chat, type: :binary_id)
    field(:content, :string)
    field(:timestamp, :utc_datetime)

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:user_id, :chat_id, :content, :timestamp])
    |> validate_required([:user_id, :chat_id, :content, :timestamp])
  end
end
