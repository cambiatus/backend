# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :phoenix, :json_library, Jason

config :bespiral, env: Mix.env

# Configures the endpoint
config :bespiral, BeSpiralWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Tbckg2miZcMoSPt4L5vSwyjKG6VHCwbg3MBp+e/tszbcvQ/a4HJOI3G4/IRYwo8m",
  render_errors: [view: BeSpiralWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BeSpiral.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :bespiral,
  ecto_repos: [BeSpiral.Repo]

config :bespiral, BeSpiral.Repo,
  pool_size: 15


config :bespiral, BeSpiral.Mailer,
  sender_email: "no-reply@cambiatus.io"

config :sentry, dsn: "https://cf10887ac4c346ebb26cbc3522578465@sentry.io/1467632",
  included_environments: [:prod],
  environment_name: Mix.env

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
