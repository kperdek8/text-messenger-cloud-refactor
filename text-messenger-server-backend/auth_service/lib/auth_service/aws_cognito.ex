defmodule TextMessengerBackend.AuthService.AWS.Cognito do
  require Logger
  use GenServer
  alias TextMessengerBackend.AuthService.AWS.SignatureV4

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    config = load_config()

    credentials = %{
      access_key: config.access_key,
      secret_key: config.secret_key,
      region: config.region,
      service: "cognito-idp"
    }
    state = %{
      credentials: credentials,
      session_token: config.session_token,
      user_pool_id: config.user_pool_id,
      client_id: config.client_id
    }
    {:ok, state}
  end

  # GenServer API

  def register(username, password, email) do
    GenServer.call(__MODULE__, {:register, username, password, email})
  end

  def login(username, password) do
    GenServer.call(__MODULE__, {:login, username, password})
  end

  # Callbacks

  @impl GenServer
  def handle_call({:register, username, password, email}, _from, %{credentials: credentials, user_pool_id: user_pool_id, client_id: client_id, session_token: session_token} = state) do
    case create_user(credentials, user_pool_id, client_id, session_token, username, password, email) do
      {:ok, user} -> {:reply, {:ok, user}, state}
      {:error, "UsernameExistsException"} -> {:reply, {:error, :username_taken}, state}
      {:error, "InvalidPasswordException"} -> {:reply, {:error, :invalid_password}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl GenServer
  def handle_call({:login, username, password}, _from, %{credentials: credentials, client_id: client_id, session_token: session_token} = state) do
    case verify_user(credentials, client_id, session_token, username, password) do
      {:ok, %{"AuthenticationResult" => %{"AccessToken" => access_token, "IdToken" => id_token, "RefreshToken" => refresh_token}}} ->
        {:reply, {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}}, state}
      {:error, "NotAuthorizedException"} ->
        {:reply, {:error, :unauthorized}, state}
      {:error, error} ->
        {:reply, {:error, :unknown_error}, state}
    end
  end

  defp load_config() do
    if System.get_env("AUTH_PROVIDER") == "mock" do
      %{
        access_key: "mock_access_key",
        secret_key: "mock_secret_key",
        session_token: nil,
        region: "mock-region-1",
        user_pool_id: "mock-pool",
        client_id: "mock-client"
      }
    else
      %{
        access_key: System.fetch_env!("AWS_ACCESS_KEY_ID"),
        secret_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
        session_token: System.get_env("AWS_SESSION_TOKEN"),
        region: System.fetch_env!("AWS_REGION"),
        user_pool_id: System.fetch_env!("AWS_USER_POOL_ID"),
        client_id: System.fetch_env!("AWS_COGNITO_CLIENT_ID")
      }
    end
  end

  defp create_user(credentials, user_pool_id, client_id, session_token, username, password, email) do
    payload = %{
      UserPoolId: user_pool_id,
      ClientId: client_id,
      Username: username,
      Password: password,
      MessageAction: "SUPPRESS",
      UserAttributes: [%{Name: "email", Value: email}, %{Name: "nickname", Value: username}]
    }

    make_cognito_request(
      credentials,
      "AWSCognitoIdentityProviderService.SignUp",
      payload,
      session_token
    )
  end

  defp verify_user(credentials, client_id, session_token, username, password) do
    payload = %{
      AuthFlow: "USER_PASSWORD_AUTH",
      AuthParameters: %{USERNAME: username, PASSWORD: password},
      ClientId: client_id
    }

    make_cognito_request(
      credentials,
      "AWSCognitoIdentityProviderService.InitiateAuth",
      payload,
      session_token
    )
  end

  # Extracted helper function for making Cognito API requests
  defp make_cognito_request(credentials, target, payload, session_token \\ nil) do
    # Convert payload to JSON
    request_body = Jason.encode!(payload)

    host =
      case System.get_env("AUTH_PROVIDER", "aws") do
        "mock" -> "localhost:4444"
        _ -> "cognito-idp.#{credentials.region}.amazonaws.com"
      end

    # Define headers
    headers = %{
      "Content-Type" => "application/x-amz-json-1.1",
      "X-Amz-Target" => target,
      "Host" => host
    }

    # Add session token if available
    headers = if session_token do
      Map.put(headers, "X-Amz-Security-Token", session_token)
    else
      headers
    end

    url =
      case System.get_env("AUTH_PROVIDER", "aws") do
        "mock" -> "http://#{host}/"
        _ -> "https://#{host}/"
      end

    # Create a signed request
    signed_request = SignatureV4.sign_request(
      "POST",
      url,
      request_body,
      headers,
      credentials
    )
    # Make the request
    case HTTPoison.request(
      "POST",
      signed_request.url,
      signed_request.body,
      Map.to_list(signed_request.headers)
    ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: _, body: body}} ->
        error_type = get_error_type_from_body(body)
        {:error, error_type}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTPRequestFailed"}
    end
  end

  defp get_error_type_from_body(body) do
    case Jason.decode(body) do
      {:ok, %{"__type" => type}} -> type
      {:ok, _} -> "UnknownErrorType"
      {:error, _} -> "Failed to parse response: #{body}"
    end
  end
end