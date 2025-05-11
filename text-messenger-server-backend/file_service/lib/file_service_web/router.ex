defmodule TextMessengerBackend.FileServiceWeb.Router do
  use TextMessengerBackend.FileServiceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TextMessengerBackend.FileServiceWeb do
    pipe_through :api
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:file_service, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
