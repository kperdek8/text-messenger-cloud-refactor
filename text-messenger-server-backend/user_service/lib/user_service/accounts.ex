defmodule TextMessengerBackend.UserService.Accounts do
  alias TextMessengerBackend.UserService.Repo
  alias TextMessengerBackend.UserService.Accounts.User
  alias TextMessenger.Protobuf

  import Ecto.Query

  @doc """
  Registers a new user with hashed password.
  """
  def register_user(attrs) do
    IO.inspect(attrs)
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Returns information about user with given id.
  """
  def get_user(id) do
    user = Repo.one(from u in User, where: u.id == ^id, select: [:id, :username])

    case user do
      nil ->
        {:error, "User not found"}

      %{id: id, username: username} ->
        # Convert the Ecto user to Protobuf user
        user_proto = %Protobuf.User{
          id: id,
          name: username
        }
        {:ok, user_proto}
    end
  end

  def get_users() do
    users = Repo.all(from u in User, select: [:id, :username])
    # Convert the query result to Protobuf struct
    users_proto = %Protobuf.Users{
      users: Enum.map(users, fn %User{id: id, username: username} ->
        %Protobuf.User{
          id: id,
          name: username
        }
      end)
    }
    {:ok, users_proto}
  end
end
