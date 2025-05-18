defmodule TextMessengerBackend.UserServiceWeb.HealthController do
  use TextMessengerBackend.UserServiceWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
