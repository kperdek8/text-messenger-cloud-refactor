defmodule TextMessengerBackend.UserServiceWeb.FallbackController do
  use TextMessengerBackend.UserServiceWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(json: TextMessengerBackend.UserServiceWeb.ErrorJSON)
    |> render("404.json")
  end
end