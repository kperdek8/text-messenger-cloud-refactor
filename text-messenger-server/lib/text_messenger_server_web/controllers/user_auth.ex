defmodule TextMessengerServerWeb.UserAuthController do
  use TextMessengerServerWeb, :controller
  alias TextMessengerServer.Accounts
  alias TextMessengerServer.AWS, as: AWS


  def register(conn, %{"username" => username, "password" => password}) do
    with {:ok, %{"UserSub" => id}} <- AWS.register(username, password, "development@test.com"),
         {:ok, _user} <- Accounts.register_user(%{id: id,username: username}) do
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
      # Maybe Ecto error
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
    case AWS.login(username, password) do
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
    end
  end
end
