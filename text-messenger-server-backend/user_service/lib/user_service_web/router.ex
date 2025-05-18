defmodule TextMessengerBackend.UserServiceWeb.Router do
  use TextMessengerBackend.UserServiceWeb, :router

  pipeline :api do
    plug(:accepts, ["json", "x-protobuf"])
  end

  pipeline :cognito_auth do
    plug TextMessengerBackend.UserServiceWeb.Auth.Cognito
  end

  scope "/", TextMessengerBackend.UserServiceWeb do
    get "/health", HealthController, :index
  end

  scope "/api/", TextMessengerBackend.UserServiceWeb do
    pipe_through :api
  end

  # Routes requiring Cognito token authorization
  scope "/api/", TextMessengerBackend.UserServiceWeb do
    pipe_through([:api, :cognito_auth])

    get("/users/:id", UserController, :fetch_user)
    get("/users/", UserController, :fetch_users)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:user_service, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TextMessengerBackend.UserServiceWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", TextMessengerBackend.UserServiceWeb do
    pipe_through :api
    match :*, "/*path", FallbackController, :not_found
  end
end
