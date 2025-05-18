defmodule TextMessengerBackend.ChatServiceWeb.Router do
  use TextMessengerBackend.ChatServiceWeb, :router

  pipeline :api do
    plug(:accepts, ["json", "x-protobuf"])
  end

  pipeline :cognito_auth do
    plug TextMessengerBackend.ChatServiceWeb.Auth.Cognito
  end

  scope "/", TextMessengerBackend.ChatServiceWeb do
    get "/health", HealthController, :index
  end

  scope "/api/", TextMessengerBackend.ChatServiceWeb do
    pipe_through :api
  end

  # Routes requiring Cognito token authorization
  scope "/api/", TextMessengerBackend.ChatServiceWeb do
    pipe_through([:api, :cognito_auth])

    post("/chats/", ChatController, :create_chat)
    get("/chats/", ChatController, :fetch_chats)
    get("/chats/:id", ChatController, :fetch_chat)
    get("/chats/:id/messages", ChatMessagesController, :fetch_messages)
    get("/chats/:id/users", ChatController, :fetch_chat_members)
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:chat_service, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", TextMessengerBackend.ChatServiceWeb do
    pipe_through :api
    match :*, "/*path", FallbackController, :not_found
  end
end
