defmodule TextMessengerClient.ChatsAPI do
  alias HTTPoison
  import TextMessengerClient.RequestHandler

  def fetch_chats(token) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "chats"])

    with {:ok, body} <- fetch_request(endpoint_url, token) do
      {:ok, body}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_chat(token, id) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "chats", id])

    with {:ok, body} <- fetch_request(endpoint_url, token) do
      {:ok, body}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def create_chat(token, name) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    params = URI.encode_query(%{name: name})
    path = Path.join([api_url, "chats"])
    endpoint_url = "#{path}?#{params}"

    with {:ok, 200, body} <- post_request(endpoint_url, "", token) do
      {:ok, body}
    else
      {:ok, status_code, error} when status_code != 200 -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  end
end
