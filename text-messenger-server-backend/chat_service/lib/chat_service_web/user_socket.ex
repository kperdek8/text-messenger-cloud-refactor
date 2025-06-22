defmodule TextMessengerBackend.ChatServiceWeb.UserSocket do
  use Phoenix.Socket
  require Logger
  alias TextMessengerBackend.ChatServiceWeb.Auth.Cognito

  channel "chat:*", TextMessengerBackend.ChatServiceWeb.ChatChannel
  channel "notifications:*", TextMessengerBackend.ChatServiceWeb.NotificationChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Cognito.verify_and_get_user(token) do
      {:ok, user_id} ->
        Logger.debug("New socket connection: #{user_id}")
        {:ok, assign(socket, user_id: user_id)}
      {:error, reason} ->
        Logger.warning("Error when verifying token connection")
        Logger.warning(reason)
        {:error, reason}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
