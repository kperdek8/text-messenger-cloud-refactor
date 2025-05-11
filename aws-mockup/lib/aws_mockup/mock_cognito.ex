  defmodule AwsMockup.Cognito do
    use Plug.Router
    use Plug.Debugger
    require Logger

    plug Plug.Parsers, parsers: [:json, AwsMockup.Parsers.AmzJson], pass: ["*/*"], json_decoder: Jason
    plug :match
    plug :dispatch

    @rsa_key JOSE.JWK.generate_key({:rsa, 2048})
    @kid "mock-kid-1234"

    get "/.well-known/jwks.json" do
      {_, jwk_map} = JOSE.JWK.to_map(@rsa_key)
      keys = [%{
        "kty" => jwk_map["kty"],
        "e" => jwk_map["e"],
        "n" => jwk_map["n"],
        "alg" => "RS256",
        "use" => "sig",
        "kid" => @kid
      }]

      send_resp(conn, 200, Jason.encode!(%{"keys" => keys}))
    end

    post "/" do
      case get_req_header(conn, "x-amz-target") do
        ["AWSCognitoIdentityProviderService.SignUp"] ->
          handle_signup(conn)

        ["AWSCognitoIdentityProviderService.InitiateAuth"] ->
          handle_auth(conn)

        _ ->
          send_resp(conn, 400, "Unsupported X-Amz-Target")
      end
    end

    match _ do
      send_resp(conn, 404, "Not Found")
    end

    defp handle_signup(conn) do
      with {:ok, body, _conn} <- Plug.Conn.read_body(conn),
           {:ok, params} <- Jason.decode(body),
           %{"Username" => username, "Password" => password} when is_binary(username) and is_binary(password) <- params,
           {:ok, user_sub} <- AwsMockup.UsersCache.add_user(username, password) do
        send_resp(conn, 200, Jason.encode!(%{"UserSub" => user_sub}))
      else
        {:error, %Jason.DecodeError{}} ->
          send_resp(conn, 400, Jason.encode!(%{"__type" => "InvalidParameterException"}))

        %{} ->
          send_resp(conn, 400, Jason.encode!(%{"__type" => "InvalidParameterException"}))

        {:error, :user_exists} ->
          send_resp(conn, 400, Jason.encode!(%{"__type" => "UsernameExistsException"}))

        error ->
          Logger.error("Unexpected error in handle_signup: #{inspect(error)}")
          send_resp(conn, 500, Jason.encode!(%{"__type" => "InternalErrorException"}))
      end
    end

    defp handle_auth(conn) do
      with {:ok, body, _conn} <- Plug.Conn.read_body(conn),
           {:ok, params} <- Jason.decode(body),
           %{"AuthFlow" => "USER_PASSWORD_AUTH", "AuthParameters" => %{"USERNAME" => username, "PASSWORD" => password}} <- params,
           {:ok, ^password} <- AwsMockup.UsersCache.get_password(username),
           {:ok, user_sub} <- AwsMockup.UsersCache.get_user_sub(username) do
        tokens = generate_tokens(user_sub)
        send_resp(conn, 200, Jason.encode!(%{"AuthenticationResult" => tokens}))
      else
        {:error, %Jason.DecodeError{}} ->
          send_resp(conn, 400, Jason.encode!(%{"__type" => "InvalidParameterException"}))
        _ ->
          send_resp(conn, 401, Jason.encode!(%{"__type" => "NotAuthorizedException"}))
      end
    end


    defp generate_tokens(username) do
      now = :os.system_time(:seconds)
      one_hour = 3600
      thirty_days = 30 * 24 * 3600

      common_claims = %{
        "sub" => username,
        "iss" => "http://localhost:4444",
        "client_id" => "mock-client-id",
        "iat" => now
      }

      id_token_claims = Map.merge(common_claims, %{"exp" => now + thirty_days, "token_use" => "id"})
      access_token_claims = Map.merge(common_claims, %{"exp" => now + thirty_days, "token_use" => "access"})

      id_token = sign_jwt(id_token_claims)
      access_token = sign_jwt(access_token_claims)

      # Placeholder opaque refresh token
      refresh_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

      %{
        "IdToken" => id_token,
        "AccessToken" => access_token,
        "RefreshToken" => refresh_token,
        "TokenType" => "Bearer",
        "ExpiresIn" => thirty_days
      }
    end

    defp sign_jwt(claims) do
      jwk = @rsa_key
      jws = JOSE.JWT.sign(jwk, %{"alg" => "RS256", "kid" => @kid}, claims)
      {_, token} = JOSE.JWS.compact(jws)
      token
    end
  end
