defmodule TextMessengerClientWeb.UserSessionController do
  use TextMessengerClientWeb, :controller

  def login(conn, %{"access-token" => access_token, "id-token" => id_token}) do
    conn
    |> put_session(:access_token, access_token)
    |> put_session(:id_token, id_token)
    |> redirect(to: ~p"/")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end
end
