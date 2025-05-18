import Config

config :auth_service, TextMessengerBackend.AuthServiceWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "mksG76sFjHcGJZDlw8rY7GPF87uKptPdrS+qnCsbDZ2CSU1tqgW/qnIYm8FRHXxI",
  watchers: [],
  server: true

config :auth_service, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
