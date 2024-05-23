defmodule Backendwebserver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Backendwebserver.Worker.start_link(arg)
      # {Backendwebserver.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Backendwebserver.Router , options: [port: 4000]}
    ]

    Logger.info("Starting web server")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Backendwebserver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
