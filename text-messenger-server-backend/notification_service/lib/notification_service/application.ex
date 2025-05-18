defmodule TextMessengerBackend.NotificationService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TextMessengerBackend.NotificationServiceWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:notification_service, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TextMessengerBackend.NotificationService.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TextMessengerBackend.NotificationService.Finch},
      # Start a worker by calling: TextMessengerBackend.NotificationService.Worker.start_link(arg)
      # {TextMessengerBackend.NotificationService.Worker, arg},
      # Start to serve requests, typically the last entry
      TextMessengerBackend.NotificationServiceWeb.Endpoint,
      TextMessengerBackend.NotificationServiceWeb.SqsConsumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TextMessengerBackend.NotificationService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TextMessengerBackend.NotificationServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
