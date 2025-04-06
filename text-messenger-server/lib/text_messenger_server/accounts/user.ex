defmodule TextMessengerServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "users" do
    field(:username, :string)

    timestamps()
  end

  @doc """
  Registration changeset for creating a user with AWS Cognito.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :username])
    |> unique_constraint([:id, :username])
    |> validate_required([:username])
  end

  @doc """
  Changeset for creating a user with AWS Cognito.
  """
  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end
end
