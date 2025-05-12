defmodule TextMessengerBackend.AuthService.SqsClient do
  require Logger
  alias TextMessengerBackend.AuthService.AWS.SignatureV4

  def send_message(queue_url, body) do
    signed_req = build_request(queue_url, body)

    case HTTPoison.post(signed_req.url, signed_req.body, signed_req.headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, :sent}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        Logger.error("[SQS] Unexpected status: #{code} - #{body}")
        {:error, {:http_error, code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[SQS] HTTPoison error: #{inspect(reason)}")
        {:error, {:httpoison_error, reason}}
    end
  end

  def build_request(queue_url, message_body) do
    host = Application.get_env(:auth_service, :sqs)[:host]
    url = Application.get_env(:auth_service, :sqs)[:url]
    session_token = Application.get_env(:auth_service, :aws)[:token]

    body = %{
      "Action" => "SendMessage",
      "MessageBody" => Jason.encode!(message_body),
      "QueueUrl" => queue_url,
      "Version" => "2012-11-05"
    }

    headers = %{
      "Content-Type" => "application/x-www-form-urlencoded",
      "Host" => host
    }

    headers = if session_token do
      Map.put(headers, "X-Amz-Security-Token", session_token)
    else
      headers
    end

    credentials = %{
      access_key: Application.get_env(:auth_service, :aws)[:access_key],
      secret_key: Application.get_env(:auth_service, :aws)[:secret_key],
      region: Application.get_env(:auth_service, :aws)[:region],
      session_token: Application.get_env(:auth_service, :aws)[:session_token],
      service: "sqs"
    }

    SignatureV4.sign_request(
      "POST",
      url,
      URI.encode_query(body),
      headers,
      credentials
    )
  end
end