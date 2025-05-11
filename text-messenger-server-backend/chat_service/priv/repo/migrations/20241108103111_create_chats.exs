defmodule TextMessengerBackend.ChatService.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    create table(:chats, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)

      timestamps()
    end

    create table(:chat_users, primary_key: false) do
      add(:chat_id, references(:chats, type: :binary_id, on_delete: :delete_all), null: false)
      add(:user_id, :string, null: false)
    end

    create(unique_index(:chat_users, [:chat_id, :user_id]))
  end
end
