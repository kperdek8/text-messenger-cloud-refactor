defmodule TextMessengerBackend.ChatServiceWeb.FallbackController do
  use TextMessengerBackend.ChatServiceWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(json: TextMessengerBackend.ChatServiceWeb.ErrorJSON)
    |> render("404.json")
  end
end