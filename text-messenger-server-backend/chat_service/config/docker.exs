import Config

config :chat_service, TextMessengerBackend.ChatServiceWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "mksG76sFjHcGJZDlw8rY7GPF87uKptPdrS+qnCsbDZ2CSU1tqgW/qnIYm8FRHXxI",
  watchers: [],
  server: true

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :chat_service, TextMessengerBackend.ChatService.Repo,
	url: database_url,
	pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :chat_service, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
