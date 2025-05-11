defmodule TextMessengerBackend.ChatService.Chats.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  # UUID v4 primary key
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "chats" do
    field(:name, :string)

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
