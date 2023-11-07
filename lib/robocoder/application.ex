defmodule Robocoder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RobocoderWeb.Telemetry,
      Robocoder.Repo,
      {DNSCluster, query: Application.get_env(:robocoder, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Robocoder.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Robocoder.Finch},
      # Start a worker by calling: Robocoder.Worker.start_link(arg)
      # {Robocoder.Worker, arg},
      # Start to serve requests, typically the last entry
      RobocoderWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Robocoder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RobocoderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
