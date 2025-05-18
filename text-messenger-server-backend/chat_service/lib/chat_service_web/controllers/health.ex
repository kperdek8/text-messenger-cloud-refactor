defmodule TextMessengerBackend.ChatServiceWeb.HealthController do
  use TextMessengerBackend.ChatServiceWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
