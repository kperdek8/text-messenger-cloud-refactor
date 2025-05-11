defmodule AwsMockup.Application do
  use Application

  def start(_type, _args) do
    children = [
      AwsMockup.UsersCache,
      {Plug.Cowboy, scheme: :http, plug: AwsMockup.Cognito, options: [port: 4444]}
    ]

    opts = [strategy: :one_for_one, name: AwsMockup.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
