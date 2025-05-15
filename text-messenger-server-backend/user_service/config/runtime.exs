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
#     PHX_SERVER=true bin/user_service start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :user_service, TextMessengerBackend.UserServiceWeb.Endpoint, server: true
end

if System.get_env("AUTH_PROVIDER") == "mock" or config_env() == :dev do
  config :user_service, :aws, access_key: "mock_access_key"
  config :user_service, :aws, secret_key: "mock_secret_key"
  config :user_service, :aws, region: "mock-region-1"
  config :user_service, :cognito, issuer: "http://localhost:4444"
  config :user_service, :cognito, jwks_url: "http://localhost:4444/.well-known/jwks.json"
  config :user_service, :aws, client_id: "mock-client-id"
  config :user_service, :sqs, queue_url: "http://localhost:9324/queues/user_events"
  config :ex_aws, :sqs,
    scheme: "http://",
    host: "localhost",
    port: 9324,
    region: "elasticmq"
else
  region = System.fetch_env!("AWS_REGION")
  pool_id = System.fetch_env!("AWS_USER_POOL_ID")

  config :user_service, :aws, access_key: System.fetch_env!("AWS_ACCESS_KEY_ID")
  config :user_service, :aws, secret_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
  config :user_service, :aws, region: region
  config :user_service, :cognito, issuer: "https://cognito-idp.#{region}.amazonaws.com/#{pool_id}"
  config :user_service, :cognito, jwks_url: "https://cognito-idp.#{region}.amazonaws.com/#{pool_id}/.well-known/jwks.json"
  config :user_service, :aws, client_id: System.fetch_env!("AWS_COGNITO_CLIENT_ID")
  config :user_service, :aws, region: region
  config :auth_service, :sqs, queue_url: System.fetch_env!("AWS_SQS_QUEUE_URL")
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

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :user_service, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :user_service, TextMessengerBackend.UserServiceWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :user_service, TextMessengerBackend.UserServiceWeb.Endpoint,
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
  #     config :user_service, TextMessengerBackend.UserServiceWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :user_service, TextMessengerBackend.UserService.Mailer,
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
