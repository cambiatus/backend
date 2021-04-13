defmodule Cambiatus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cambiatus,
      version: "1.7.8",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Cambiatus.Application, []},
      extra_applications: [:sentry, :logger, :runtime_tools, :bamboo, :plug, :magic_number]
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
      {:bamboo, "~> 1.1"},
      {:hackney,
       github: "benoitc/hackney", override: true, ref: "d8a0d979b9bdb916fe090bf1d5b076e35c2efc33"},
      {:uuid, "~> 1.1"},
      {:magic_number, "~> 0.0.4"},
      {:mogrify, "~> 0.8.0"},
      {:ex_phone_number, "~> 0.2"},

      # Phoenix
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},

      # Absinthe Packages
      {:absinthe, "~> 1.4"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:absinthe_relay, "~> 1.4.6"},
      {:dataloader, "~> 1.0.0"},

      # EOS/Blockchain Packages
      {:ipfs, "~> 0.1.0"},
      {:eosrpc, "~> 0.6.2"},
      {:hashids, "~> 2.0"},

      # Sentry
      {:sentry, "~> 6.4"},
      {:plug_cowboy, "~> 2.3"},

      # AWS Packages
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},

      # Push Notification Packages
      {:web_push_encryption,
       git: "https://github.com/danhper/elixir-web-push-encryption.git", ref: "97297fd3db"},

      # Dev only
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:edeliver, "~> 1.6"},
      {:rename, "~> 0.1.0", only: :dev},
      {:distillery, "~> 2.0", runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},

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
      test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
