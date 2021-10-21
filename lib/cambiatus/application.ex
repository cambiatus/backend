defmodule Cambiatus.Application do
  @moduledoc false

  use Application

  require Logger

  alias Cambiatus.{Repo, DbListener, PubSub}
  alias CambiatusWeb.Endpoint

  def start(_type, _args) do
    children = [
      Repo,
      DbListener,
      Endpoint,
      {Phoenix.PubSub, name: PubSub},
      {Absinthe.Subscription, [Endpoint]},
      {Oban, oban_config()}
    ]

    Logger.add_backend(Sentry.LoggerBackend)

    opts = [strategy: :one_for_one, name: Cambiatus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CambiatusWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def oban_config do
    Application.fetch_env!(:cambiatus, Oban)
  end
end
