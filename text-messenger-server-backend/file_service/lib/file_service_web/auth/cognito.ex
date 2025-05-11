defmodule TextMessengerServerWeb.Auth.Cognito do
  import Plug.Conn
  use Joken.Config

  @behaviour Plug

  @region System.get_env("AWS_REGION")
  @user_pool_id System.get_env("AWS_USER_POOL_ID")
  @client_id System.get_env("AWS_COGNITO_CLIENT_ID")

  @jwks_url "https://cognito-idp.#{@region}.amazonaws.com/#{@user_pool_id}/.well-known/jwks.json"
  @issuer "https://cognito-idp.#{@region}.amazonaws.com/#{@user_pool_id}"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, token} <- get_token(conn),
         {:ok, user} <- verify_and_get_user(token) do
      assign(conn, :user, user)
    else
      _ -> send_resp(conn, 401, "Unauthorized") |> halt()
    end
  end

  def verify_and_get_user(token) do
    with {:ok, claims} <- verify_token(token),
         cognito_sub <- claims["sub"],
         {:ok, user} <- get_user(cognito_sub) do
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid_token}
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :missing_token}
    end
  end

  defp verify_token(token) do
    with {:ok, jwks} <- fetch_jwks(),
         {:ok, header} <- Joken.peek_header(token),
         {:ok, jwk} <- find_jwk(jwks, header["kid"]) do

      signer = Joken.Signer.create("RS256", jwk)

      token_config =
        Joken.Config.default_claims()
        |> Joken.Config.add_claim("iss", fn -> @issuer end, &(&1 == @issuer))
        |> Joken.Config.add_claim("client_id", fn -> @client_id end, &(&1 == @client_id || Enum.member?(&1, @client_id)))
        |> Joken.Config.add_claim("token_use", fn -> "id" end, &(&1 == "id" || &1 == "access"))

      Joken.verify_and_validate(token_config, token, signer)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_jwk(jwks, kid) do
    case Enum.find(jwks["keys"], fn key -> key["kid"] == kid end) do
      nil -> {:error, :key_not_found}
      jwk -> {:ok, jwk}
    end
  end

  defp fetch_jwks do
    case HTTPoison.get(@jwks_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Failed to fetch JWKS with status code: #{status_code}"}
      {:error, reason} ->
        {:error, "Failed to fetch JWKS: #{inspect(reason)}"}
    end
  end

  defp get_user(cognito_sub) do
    case TextMessengerServer.Accounts.get_user(cognito_sub) do
      nil -> {:error, :user_not_found}
      user -> user
    end
  end
end
