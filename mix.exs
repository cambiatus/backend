defmodule Cambiatus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cambiatus,
      version: "1.7.7",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        prod: [
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Cambiatus.Application, []},
      extra_applications: [:sentry, :logger, :runtime_tools, :bamboo, :plug]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:calendar, "~> 1.0.0", override: true},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:tesla, "~> 1.2.1"},
      {:jason, "~> 1.0.0"},
      {:cors_plug, "~> 1.5"},
      {:poolboy, ">= 0.0.0"},
      {:timex, "~> 3.4"},
      {:bamboo, "~> 1.1"},
      {:plug_cowboy, "~> 1.0"},
      {:absinthe, "~> 1.4"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:absinthe_relay, "~> 1.4.6"},
      {:dataloader, "~> 1.0.0"},
      {:ipfs, "~> 0.1.0"},
      {:eosrpc, "~> 0.5.0"},
      {:sentry, "~> 6.4"},
      {:hashids, "~> 2.0"},

      # web_push
      {:web_push_encryption,
       git: "https://github.com/danhper/elixir-web-push-encryption.git", ref: "97297fd3db"},

      # dev
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:edeliver, "~> 1.6"},
      {:rename, "~> 0.1.0", only: :dev},
      {:distillery, "~> 2.0", runtime: false},

      # test
      {:ex_machina, "~> 2.3", only: :test},
      {:mox, "~> 0.5.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
