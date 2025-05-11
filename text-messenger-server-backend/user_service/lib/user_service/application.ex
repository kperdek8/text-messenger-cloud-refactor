defmodule TextMessengerBackend.UserService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TextMessengerBackend.UserServiceWeb.Telemetry,
      TextMessengerBackend.UserService.Repo,
      {DNSCluster, query: Application.get_env(:user_service, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TextMessengerBackend.UserService.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TextMessengerBackend.UserService.Finch},
      # Start a worker by calling: TextMessengerBackend.UserService.Worker.start_link(arg)
      # {TextMessengerBackend.UserService.Worker, arg},
      # Start to serve requests, typically the last entry
      TextMessengerBackend.UserServiceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TextMessengerBackend.UserService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TextMessengerBackend.UserServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
