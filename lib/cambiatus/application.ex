defmodule Cambiatus.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      Cambiatus.Repo,
      Cambiatus.DbListener,
      CambiatusWeb.Endpoint,
      {Absinthe.Subscription, [CambiatusWeb.Endpoint]},
      %{
        id: NodeJS,
        start: {NodeJS, :start_link, [[path: "./nodejs_auth/dist/js", pool_size: 4]]}
      }
    ]

    opts = [strategy: :one_for_one, name: Cambiatus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CambiatusWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
