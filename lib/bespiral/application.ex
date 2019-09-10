defmodule BeSpiral.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      BeSpiral.Repo,
      BeSpiral.DbListener,
      BeSpiralWeb.Endpoint,
      {Absinthe.Subscription, [BeSpiralWeb.Endpoint]}
    ]

    opts = [strategy: :one_for_one, name: BeSpiral.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BeSpiralWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
