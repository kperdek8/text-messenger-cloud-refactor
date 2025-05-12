defmodule TextMessengerBackend.AuthServiceWeb.UserAuthController do
  use TextMessengerBackend.AuthServiceWeb, :controller
  alias TextMessengerBackend.AuthService.AWS.Cognito, as: Cognito
  alias TextMessengerBackend.AuthService.SqsClient, as: SqsClient
  alias TextMessengerBackend.AuthService.Events

  defmodule RegistrationMessage do
    @derive Jason.Encoder
    defstruct [:event, :user_id, :username]
  end

  def register(conn, %{"username" => username, "password" => password}) do
    with {:ok, %{"UserSub" => id}} <- Cognito.register(username, password, "development@test.com")
      do
        queue_url = Application.get_env(:auth_service, :sqs)[:queue_url]
        message = Events.UserCreated.new(%{
          id: id,
          username: username,
          email: "development@test.com",
        })
        SqsClient.send_message(queue_url, message) # TODO: Add fallback mechanism
        conn
        |> put_status(:created)
        |> put_resp_content_type("application/json")
        |> json(%{message: "Registration successful!"})
    else
      {:error, :username_taken} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> json(%{
          error: "registration_failed",
          details: "Username taken!"
        })
      {:error, :invalid_password} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> json(%{
          error: "registration_failed",
          details: "Password does not match requirements!"
        })
      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> json(%{
          error: "registration_failed",
          details: "Unknown error occured, ask administrator for help"
        })
    end
  end

  def login(conn, %{"username" => username, "password" => password}) do
    case Cognito.login(username, password) do
      {:ok, %{access_token: access_token, id_token: id_token, refresh_token: refresh_token}} ->
        conn
        |> put_status(:ok)
        |> put_resp_content_type("application/json")
        |> json(%{message: "Login successful!",access_token: access_token, id_token: id_token, refresh_token: refresh_token})

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> json(%{error: "Invalid password"})
      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> put_resp_content_type("application/json")
        |> json(%{error: "Internal Server Error"})
    end
  end
end
