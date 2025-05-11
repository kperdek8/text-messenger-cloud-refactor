defmodule TextMessengerBackend.AuthServiceWeb.Router do
  use TextMessengerBackend.AuthServiceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/", TextMessengerBackend.AuthServiceWeb do
    pipe_through :api

    post("/auth/register", UserAuthController, :register)
    post("/auth/login", UserAuthController, :login)
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:auth_service, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", TextMessengerBackend.AuthServiceWeb do
    pipe_through :api
    match :*, "/*path", FallbackController, :not_found
  end
end
