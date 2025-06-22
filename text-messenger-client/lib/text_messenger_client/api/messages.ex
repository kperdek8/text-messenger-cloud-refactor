defmodule TextMessengerClient.MessagesAPI do
  alias HTTPoison
  import TextMessengerClient.RequestHandler

  def fetch_messages(token, id) do
    api_url = Application.fetch_env!(:text_messenger_client, :api_url)
    endpoint_url = Path.join([api_url, "chats", id, "messages"])

    with {:ok, body} <- fetch_request(endpoint_url, token) do
      {:ok, body}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
