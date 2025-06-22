defmodule TextMessengerClient.UsersAPI do
  alias HTTPoison
  import TextMessengerClient.RequestHandler
  alias TextMessenger.Protobuf.{Users, User}

  def login(username, password) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    IO.inspect(api_url)
    params = URI.encode_query(%{username: username, password: password})
    path = Path.join([api_url, "auth", "login"])
    endpoint_url = "#{path}?#{params}"
    with {:ok, 200, %{"access_token" => access_token, "id_token" => id_token, "refresh_token" => refresh_token}} <- post_request(endpoint_url, "") do
      {:ok, {access_token, id_token, refresh_token}}
    else
      {:ok, status_code, error} when status_code != 200 -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  end

  def register(username, password) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    params = URI.encode_query(%{username: username, password: password})
    path = Path.join([api_url, "auth", "register"])
    endpoint_url = "#{path}?#{params}"

    with {:ok, 201, %{"message" => message}} <- post_request(endpoint_url, "") do
      {:ok, message}
    else
      {:ok, 422, %{"details" => details}} -> {:error, details}
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_chat_members(token, id) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "chats", id, "users"])

    with {:ok, %{users: ids} = body} <- fetch_request(endpoint_url, token) do
      users =
        Enum.map(ids, fn id ->
          case fetch_user(token, id) do
            %User{} = user -> user
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      {:ok, users}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_users(token) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "users"])

    with {:ok, body} <- fetch_request(endpoint_url, token) do
      Users.decode(body)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_user(token, id) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "users", id])

    with {:ok, body} <- fetch_request(endpoint_url, token) do
      User.decode(body)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
