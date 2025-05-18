import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/chat_service start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :chat_service, TextMessengerBackend.ChatServiceWeb.Endpoint, server: true
end

runtime_env = System.get_env("RUNTIME_ENV") || Atom.to_string(config_env())
runtime_env = String.to_atom(runtime_env)

case runtime_env do
  :dev ->
    config :chat_service, :aws, access_key: "mock_access_key"
    config :chat_service, :aws, secret_key: "mock_secret_key"
    config :chat_service, :aws, region: "mock-region-1"
    config :chat_service, :aws, session_token: nil
    config :chat_service, :cognito, issuer: "http://localhost:4444"
    config :chat_service, :cognito, jwks_url: "http://localhost:4444/.well-known/jwks.json"
    config :chat_service, :aws, client_id: "mock-client-id"
    config :chat_service, :sqs, host: "localhost:9324"
    config :chat_service, :sqs, url: "http://localhost:9324/"
    config :chat_service, :sqs, queue_url: "http://localhost:9324/queues/user_added_queue"
  :docker ->
    cognito_host = System.get_env("COGNITO_HOST") || "host.docker.internal:4444"
    sqs_host = System.get_env("SQS_HOST") || "host.docker.internal"
    config :chat_service, :aws, access_key: "mock_access_key"
    config :chat_service, :aws, secret_key: "mock_secret_key"
    config :chat_service, :aws, region: "mock-region-1"
    config :chat_service, :aws, session_token: nil
    config :chat_service, :cognito, issuer: "http://localhost:4444"
    config :chat_service, :cognito, jwks_url: "http://#{cognito_host}:4444/.well-known/jwks.json"
    config :chat_service, :aws, client_id: "mock-client-id"
    config :chat_service, :sqs, host: sqs_host
    config :chat_service, :sqs, url: "http://#{sqs_host}:9324/"
    config :chat_service, :sqs, queue_url: "http://#{sqs_host}:9324/queues/user_added_queue"
  :prod ->
    region = System.get_env("AWS_REGION")
    pool_id = System.get_env("AWS_USER_POOL_ID")
    config :chat_service, :aws, access_key: System.fetch_env!("AWS_ACCESS_KEY_ID")
    config :chat_service, :aws, secret_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    config :chat_service, :aws, session_token: System.get_env("AWS_SESSION_TOKEN")
    config :chat_service, :aws, region: region
    config :chat_service, :cognito, issuer: "https://cognito-idp.#{region}.amazonaws.com/#{pool_id}"
    config :chat_service, :cognito, jwks_url: "https://cognito-idp.#{region}.amazonaws.com/#{pool_id}/.well-known/jwks.json"
    config :chat_service, :aws, client_id: System.get_env("AWS_COGNITO_CLIENT_ID")
    config :chat_service, :aws, region: region
    config :chat_service, :sqs, host: "sqs.#{region}.amazonaws.com"
    config :chat_service, :sqs, url: "https://sqs.#{region}.amazonaws.com/"
    config :chat_service, :sqs, queue_url: System.fetch_env!("AWS_SQS_QUEUE_URL")
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "0.0.0.0"
  port = String.to_integer(System.get_env("PORT") || "4002")

  config :chat_service, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :chat_service, TextMessengerBackend.ChatServiceWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  database_url =
	System.get_env("DATABASE_URL") ||
	  raise """
	  environment variable DATABASE_URL is missing.
	  For example: ecto://USER:PASS@HOST/DATABASE
	  """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :chat_service, TextMessengerBackend.ChatService.Repo,
    ssl: true,
    ssl_opts: [
      verify: :verify_none
    ],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :chat_service, TextMessengerBackend.ChatServiceWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :chat_service, TextMessengerBackend.ChatServiceWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :chat_service, TextMessengerBackend.ChatService.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
