defmodule TextMessengerServerWeb.UserSocket do
  use Phoenix.Socket

  alias TextMessengerServerWeb.Auth.Cognito

  channel "chat:*", TextMessengerServerWeb.ChatChannel
  channel "notifications:*", TextMessengerServerWeb.NotificationChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Cognito.verify_and_get_user(token) do
      {:ok, user} ->
        {:ok, assign(socket, user_id: user.id, username: user.name)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
