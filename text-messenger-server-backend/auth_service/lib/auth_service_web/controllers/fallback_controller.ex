defmodule TextMessengerBackend.AuthServiceWeb.FallbackController do
  use TextMessengerBackend.AuthServiceWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(json: TextMessengerBackend.AuthServiceWeb.ErrorJSON)
    |> render("404.json")
  end
end