defmodule TextMessengerServer.AWS do
  require Logger
  use GenServer
  alias TextMessengerServer.AWS.SignatureV4

  @access_key_id System.get_env("AWS_ACCESS_KEY_ID")
  @secret_access_key System.get_env("AWS_SECRET_ACCESS_KEY")
  @session_token System.get_env("AWS_SESSION_TOKEN")
  @region System.get_env("AWS_REGION")
  @user_pool_id System.get_env("AWS_USER_POOL_ID")
  @client_id System.get_env("AWS_COGNITO_CLIENT_ID")

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    credentials = %{
      access_key: @access_key_id,
      secret_key: @secret_access_key,
      region: @region,
      service: "cognito-idp"
    }
    state = %{credentials: credentials}
    {:ok, state}
  end

  def register(username, password, email) do
    GenServer.call(__MODULE__, {:register, username, password, email})
  end

  def login(username, password) do
    GenServer.call(__MODULE__, {:login, username, password})
  end

  # Callbacks

  @impl GenServer
  def handle_call({:register, username, password, email}, _from, %{credentials: credentials} = state) do
    case create_user(credentials, username, password, email) do
      {:ok, user} -> {:reply, {:ok, user}, state}
      {:error, "UsernameExistsException"} -> {:reply, {:error, :username_taken}, state}
      {:error, "InvalidPasswordException"} -> {:reply, {:error, :invalid_password}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  defp create_user(credentials, username, password, email) do
    payload = %{
      UserPoolId: @user_pool_id,
      ClientId: @client_id,
      Username: username,
      Password: password,
      MessageAction: "SUPPRESS",
      UserAttributes: [%{Name: "email", Value: email}, %{Name: "nickname", Value: username}]
    }

    IO.inspect(payload)

    make_cognito_request(
      credentials,
      "AWSCognitoIdentityProviderService.SignUp",
      payload
    )
  end

  @impl GenServer
  def handle_call({:login, username, password}, _from, %{credentials: credentials} = state) do
    case verify_user(credentials, username, password) do
      {:ok, %{"AuthenticationResult" => %{"AccessToken" => access_token, "IdToken" => id_token, "RefreshToken" => refresh_token}}} ->
        {:reply, {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}}, state}
      {:error, "NotAuthorizedException"} ->
        {:reply, {:error, :unauthorized}, state}
      {:error, error} ->
        IO.inspect(error)
        {:reply, {:error, :unknown_error}, state}
    end
  end

  defp verify_user(credentials, username, password) do
    payload = %{
      AuthFlow: "USER_PASSWORD_AUTH",
      AuthParameters: %{USERNAME: username, PASSWORD: password},
      ClientId: @client_id
    }

    make_cognito_request(
      credentials,
      "AWSCognitoIdentityProviderService.InitiateAuth",
      payload
    )
  end

  # Extracted helper function for making Cognito API requests
  defp make_cognito_request(credentials, target, payload) do
    # Convert payload to JSON
    request_body = Jason.encode!(payload)

    # Define headers
    headers = %{
      "Content-Type" => "application/x-amz-json-1.1",
      "X-Amz-Target" => target,
      "Host" => "cognito-idp.#{credentials.region}.amazonaws.com"
    }

    # Add session token if available
    headers = if @session_token do
      Map.put(headers, "X-Amz-Security-Token", @session_token)
    else
      headers
    end

    # Create a signed request
    signed_request = SignatureV4.sign_request(
      "POST",
      "https://cognito-idp.#{credentials.region}.amazonaws.com/",
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

  defp get_error_type({_, response}) do
    get_error_type_from_body(response.body)
  end
end