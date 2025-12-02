defmodule Cambiatus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cambiatus,
      version: "2.0.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      elixirc_options: [no_gradual_types: false]
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
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.26.0"},
      {:cowboy, "~> 2.0"},
      {:tesla, "~> 1.3"},
      {:jason, "~> 1.4"},
      {:cors_plug, "~> 3.0"},
      {:poolboy, ">= 0.0.0"},
      {:timex, "~> 3.7"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.24"},
      {:uuid, "~> 1.1"},
      {:magic_number, "~> 0.0.4"},
      {:mogrify, "~> 0.8.0"},
      {:ssl_verify_fun, "~> 1.1.7", manager: :rebar3, override: true},

      # Formatters
      {:ex_phone_number, "~> 0.2"},
      {:number, "~> 1.0"},
      {:earmark, "~> 1.4"},
      {:html_sanitize_ex, "~> 1.4"},
      {:ex_cldr, "~> 2.40"},
      {:ex_cldr_dates_times, "~> 2.19"},

      # Email capabilities
      {:swoosh, "~> 1.19"},
      {:phoenix_swoosh, "~> 1.2"},

      # Phoenix
      {:phoenix, "~> 1.7.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.0"},
      {:plug_cowboy, "~> 2.0"},

      # Absinthe Packages
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5.0"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_relay, "~> 1.5.0"},
      {:dataloader, "~> 1.0.0"},

      # EOS/Blockchain Packages
      {:eosrpc, "~> 0.6.2"},
      {:hashids, "~> 2.0"},
      {:eosjs_auth_wrapper, "~> 0.1.7"},

      # Sentry
      {:sentry, "~> 10.0"},

      # AWS Packages
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:configparser_ex, "~> 4.0"},

      # Push Notification Packages
      {:web_push_encryption, "~> 0.3.1"},

      # Background processing
      {:oban, "~> 2.18"},

      # Dev only
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: :dev},

      # Test Only
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:mox, "~> 1.1", only: :test}
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
        "sobelow --config",
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
