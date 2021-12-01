defmodule Cambiatus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cambiatus,
      version: "2.0.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {Cambiatus.Application, []},
      extra_applications: [:runtime_tools, :plug, :magic_number]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Basic packages
      {:calendar, "~> 1.0.0", override: true},
      {:ecto_sql, "~> 3.5"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 2.0"},
      {:tesla, "~> 1.2.1"},
      {:jason, "~> 1.2.0"},
      {:cors_plug, "~> 1.5"},
      {:poolboy, ">= 0.0.0"},
      {:timex, "~> 3.4"},
      {:poison, "~> 3.0"},
      {:hackney,
       github: "benoitc/hackney", override: true, ref: "d8a0d979b9bdb916fe090bf1d5b076e35c2efc33"},
      {:uuid, "~> 1.1"},
      {:magic_number, "~> 0.0.4"},
      {:mogrify, "~> 0.8.0"},

      # Formatters
      {:ex_phone_number, "~> 0.2"},
      {:number, "~> 1.0"},
      {:earmark, "~> 1.4"},

      # Email capabilities
      {:swoosh, "~> 1.0"},
      {:phoenix_swoosh, "~> 0.3"},

      # Phoenix
      {:phoenix, "~> 1.5.3"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},

      # Absinthe Packages
      {:absinthe, "~> 1.6"},
      {:absinthe_plug, "~> 1.5.0"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_relay, "~> 1.5.0"},
      {:dataloader, "~> 1.0.0"},

      # EOS/Blockchain Packages
      {:eosrpc, "~> 0.6.2"},
      {:hashids, "~> 2.0"},
      {:eosjs_auth_wrapper, "~> 0.1.7"},

      # Sentry
      {:sentry, "8.0.0"},
      {:plug_cowboy, "~> 2.3"},

      # AWS Packages
      {:ex_aws, "~> 2.2.1"},
      {:ex_aws_s3, "~> 2.1"},
      {:configparser_ex, "~> 4.0"},

      # Push Notification Packages
      {:web_push_encryption, "~> 0.3.0"},

      # Background processing
      {:oban, "~> 2.9"},

      # Dev only
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},

      # Test Only
      {:ex_machina, "~> 2.3", only: :test},
      {:faker, "~> 0.14", only: :test},
      {:mox, "~> 0.5.0", only: :test}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/country_seeds.exs",
        "test"
      ],
      check: [
        "compile --warnings-as-errors --all warnings",
        "format --check-formatted",
        "credo"
      ]
    ]
  end

  defp releases do
    [
      dev: [
        include_executables_for: [:unix],
        include_erts: true,
        strip_beams: false,
        quiet: false
      ],
      demo: [
        include_executables_for: [:unix],
        include_erts: true,
        strip_beams: true,
        quiet: false
      ],
      cambiatus: [
        include_executables_for: [:unix],
        include_erts: true,
        strip_beams: true,
        quiet: false
      ]
    ]
  end
end
