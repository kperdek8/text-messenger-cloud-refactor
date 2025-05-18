defmodule TextMessengerBackend.FileServiceWeb.FileController do
  use TextMessengerBackend.FileServiceWeb, :controller
  alias TextMessengerBackend.FileService.FileAccess

  def show(conn, %{"chat_id" => chat_id, "message_id" => message_id, "file" => file}) do
    key = "#{chat_id}/#{message_id}/#{file}"
    if not FileAccess.object_exists?(key) do
      conn
      |> put_status(:not_found)
      |> json(%{status: 404, error: "File not found"})
    else
      case FileAccess.generate_presigned_get_url(key) do
        {:ok, url} ->
          conn
          |> put_status(:ok)
          |> put_resp_content_type("application/json")
          |> json(%{status: 200, url: url})
        _ ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{status: 500, error: "Internal server error"})
      end
    end
  end

  def upload(conn, %{"chat_id" => chat_id, "message_id" => message_id, "file" => file, "content_type" => content_type}) do
    key = "#{chat_id}/#{message_id}/#{file}"
    if FileAccess.object_exists?(key) do
      conn
      |> put_status(:conflict)
      |> json(%{status: 409, error: "File already exists"})
    else
      case FileAccess.generate_presigned_put_url(key, content_type) do
        {:ok, url} ->
          conn
          |> put_status(:ok)
          |> put_resp_content_type("application/json")
          |> json(%{status: 200, url: url})

        _ ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{status: 500, error: "Internal server error"})
      end
    end
  end
end
