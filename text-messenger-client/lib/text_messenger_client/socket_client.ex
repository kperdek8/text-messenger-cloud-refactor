defmodule TextMessengerClient.SocketClient do
  require Logger

  alias TextMessengerClient.Helpers.JWT

  defmodule WebSocket do
    defstruct [:socket, :chat_channel, :notif_channel, :access_token, :id_token, :chat_id, :liveview_pid]
  end

  def start(access_token, id_token) do
    socket_url = Application.fetch_env!(:text_messenger_client, :socket_url)

    {:ok, socket} = PhoenixClient.Socket.start_link(
      url: socket_url,
      params: %{token: access_token}
    )

    wait_for_connection(socket)
    notif_channel =
      case join_notif_channel(socket, id_token) do
        {:ok, channel} -> channel
        {:error, %{"reason" => reason}} ->
          IO.inspect("Could not join notification channel: #{reason}")
          nil
      end

    {:ok, %WebSocket{socket: socket, chat_channel: nil, notif_channel: notif_channel, access_token: access_token, id_token: id_token, chat_id: nil}}
  end

  def send_message(%WebSocket{chat_channel: channel, chat_id: chat_id}, content) do
    Logger.info("Sending chat message to server")
    encoded_content = Base.encode64(content)
    payload = %{content: encoded_content}

    case PhoenixClient.Channel.push(channel, "new_message", payload) do
      {:ok, _message} -> :ok
      {:error, reason} ->
        Logger.error("Failed to push new_message: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def add_user(%WebSocket{chat_channel: channel}, target_user_id) do
    Logger.info("Sending add_user request to server")
    payload = %{user_id: target_user_id}

    case PhoenixClient.Channel.push_async(channel, "add_user", payload) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("Failed to push add_user: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def kick_user(%WebSocket{chat_channel: channel}, target_user_id) do
    Logger.info("Sending kick_user request to server")
    payload = %{user_id: target_user_id}

    case PhoenixClient.Channel.push_async(channel, "kick_user", payload) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("Failed to push add_user: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def change_chat(%WebSocket{socket: socket, chat_channel: channel} = websocket, new_chat_id) do
    Logger.info("Changing chat channel")
    if channel != nil do
      PhoenixClient.Channel.leave(channel)
    end

    case join_chat(socket, new_chat_id) do
      {:ok, new_channel} ->
        {:ok, %WebSocket{websocket | chat_channel: new_channel, chat_id: new_chat_id}}
      {:error, reason} ->
        Logger.error("Failed to join new chat room: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp join_chat(socket, chat_id) do
    Logger.info("Joining chat channel")
    topic = "chat:#{chat_id}"

    case PhoenixClient.Channel.join(socket, topic) do
      {:ok, _, channel} ->
        {:ok, channel}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp join_notif_channel(socket, token) do
    Logger.info("Joining notification channel")
    {:ok, payload} = JWT.decode_payload(token)
    username = payload["sub"]
    topic = "notifications:#{username}"

    case PhoenixClient.Channel.join(socket, topic) do
      {:ok, _, channel} ->
        {:ok, channel}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp wait_for_connection(socket_pid) do
    unless PhoenixClient.Socket.connected?(socket_pid) do
      :timer.sleep(100)
      wait_for_connection(socket_pid)
    end
  end

  def stop(%WebSocket{chat_channel: chat_channel, notif_channel: notif_channel, socket: socket}) do
    if Process.alive?(chat_channel) do
      PhoenixClient.Channel.leave(chat_channel)
    end
    if Process.alive?(notif_channel) do
      PhoenixClient.Channel.leave(notif_channel)
    end
    if Process.alive?(socket) do
      PhoenixClient.Socket.stop(socket)
    end
  end
end
