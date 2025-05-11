defmodule TextMessengerBackend.FileService.Repo do
  use Ecto.Repo,
    otp_app: :file_service,
    adapter: Ecto.Adapters.Postgres
end
