defmodule TextMessengerBackend.UserService.EventHandlers do
  require Logger
  alias TextMessengerBackend.UserService.Accounts

  def handle_user_created(%{"id" => id, "username" => username, "email" => email}) do
    Logger.debug("Handling user.created for #{username} (#{id})")

    case Accounts.register_user(%{
          id: id,
          username: username,
          email: email
        }) do
      {:ok, user} ->
        :ok
      {:error, reason} ->
        Logger.error("Failed to register user #{username} (#{id}): #{inspect(reason)}")
        {:error, reason}
    end
  end
end
