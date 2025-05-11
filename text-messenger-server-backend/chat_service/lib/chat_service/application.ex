defmodule TextMessengerBackend.ChatService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TextMessengerBackend.ChatServiceWeb.Telemetry,
      TextMessengerBackend.ChatService.Repo,
      {DNSCluster, query: Application.get_env(:chat_service, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TextMessengerBackend.ChatService.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TextMessengerBackend.ChatService.Finch},
      # Start a worker by calling: TextMessengerBackend.ChatService.Worker.start_link(arg)
      # {TextMessengerBackend.ChatService.Worker, arg},
      # Start to serve requests, typically the last entry
      TextMessengerBackend.ChatServiceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TextMessengerBackend.ChatService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TextMessengerBackend.ChatServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
