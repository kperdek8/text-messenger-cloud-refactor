defmodule TextMessengerClient.RequestHandler do
  require Logger

  def fetch_request(endpoint, token \\ nil) do
    headers = [
      {"Content-Type", "application/json"}
    ]

    headers = if token, do: [{"Authorization", "Bearer #{token}"} | headers], else: headers

    Logger.info("Sending GET request #{endpoint}")

    case HTTPoison.get(endpoint, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 401, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => _error, "reason" => reason}} ->
            {:error, reason}

          {:ok, %{"error" => error}} ->
            {:error, "Unauthorized: #{error}"}

          {:error, _reason} ->
            {:error, "Failed to decode error response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, status_code}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP error: #{reason}"}
    end
  end

  def post_request(endpoint, payload, token \\ nil) do
    headers = [
      {"Content-Type", "application/json"},
    ]

    headers = if token, do: [{"Authorization", "Bearer #{token}"} | headers], else: headers

    Logger.info("Sending POST request #{endpoint}")

    case HTTPoison.post(endpoint, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: response_headers}} ->
        content_type = get_content_type(response_headers)

        case content_type do
          "application/json" ->
            {:ok, status_code, Jason.decode!(body)}

          "application/x-protobuf" ->
            {:ok, status_code, body} # Leave protobuf decoding to calling function

        _ ->
          Logger.warning("Unsupported content type #{content_type} in response")
          {:error, "Unsupported content type: #{content_type}"}
      end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP error: #{reason}"}
    end
  end


  defp get_content_type(headers) do
    case Enum.find(headers, fn {key, _} -> String.downcase(key) == "content-type" end) do
      nil -> nil
      {_, type} -> String.split(type, ";") |> List.first() |> String.trim()
    end
  end
end
