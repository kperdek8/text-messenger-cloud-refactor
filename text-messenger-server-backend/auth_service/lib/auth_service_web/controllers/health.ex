defmodule TextMessengerBackend.AuthServiceWeb.HealthController do
  use TextMessengerBackend.AuthServiceWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
