import Config

database_url =
	System.get_env("DATABASE_URL") ||
	  raise """
	  environment variable DATABASE_URL is missing.
	  For example: ecto://USER:PASS@HOST/DATABASE
	  """

config :file_service, TextMessengerBackend.FileService.Repo,
	ssl: true,
	ssl_opts: [
	  verify: :verify_none
	],
	url: database_url,
	pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
	socket_options: maybe_ipv6

# Configures Swoosh API Client
config :swoosh,
  api_client: Swoosh.ApiClient.Finch,
  finch_name: TextMessengerBackend.FileService.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
