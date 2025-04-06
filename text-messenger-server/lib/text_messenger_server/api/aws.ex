defmodule TextMessengerServer.AWS do
  require Logger
  use GenServer

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
    client =
      AWS.Client.create(@access_key_id, @secret_access_key, @session_token, @region)
    state = %{client: client}
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
  def handle_call({:register, username, password, email}, _from, %{client: client} = state) do
    case create_user(client, username, password, email) do
      {:ok, user} ->{:reply, {:ok, user}, state}
      {:error, "UsernameExistsException"} -> {:reply, {:error, :username_taken}, state}
      {:error, "InvalidPasswordException"} -> {:reply, {:error, :invalid_password}, state}
    end
  end

  defp create_user(client, username, password, email) do
    case AWS.CognitoIdentityProvider.sign_up(client, %{
      UserPoolId: @user_pool_id,
      ClientId: @client_id,
      Username: username,
      Password: password,
      MessageAction: "SUPPRESS",
      UserAttributes: [%{Name: "email", Value: email}, %{Name: "nickname", Value: username}]
    }) do
      {:ok, user, response} ->
        {:ok, user}
      {:error, response} ->
        IO.inspect(get_error_type(response))
        {:error, get_error_type(response)}
    end
  end

  @impl GenServer
  def handle_call({:login, username, password}, _from, %{client: client} = state) do
    case verify_user(client, username, password) do
      {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}} -> {:reply, {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}}, state}
      {:error, "NotAuthorizedException"} ->
        {:reply, {:error, :unauthorized}, state}
      {:error, error} ->
        IO.inspect(error)
        {:reply, {:error, :unkown_error}, state}
    end
  end

  defp verify_user(client, username, password) do
    case AWS.CognitoIdentityProvider.initiate_auth(client, %{
      AuthFlow: "USER_PASSWORD_AUTH",
      AuthParameters: %{USERNAME: username, PASSWORD: password},
      ClientId: @client_id
    }) do
      {:ok, %{"AuthenticationResult" => %{"AccessToken" => access_token, "IdToken" => id_token, "RefreshToken" => refresh_token}}, _body} -> {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}}
      {:error, response} -> {:error, get_error_type(response)}
    end
  end

  defp get_error_type({_, response}) do
    case Jason.decode(response.body) do
      {:ok, %{"__type" => type}} -> type
      {:ok, _} -> "UnknownErrorType"
      {:error, _} -> "Failed to parse response: #{response}"
    end
  end
end
