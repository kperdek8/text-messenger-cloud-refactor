defmodule TextMessengerBackend.NotificationServiceWeb.HealthController do
  use TextMessengerBackend.NotificationServiceWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
