defmodule Cambiatus.Release do
  @moduledoc """
  Module that runs custom commands, used on production to run tasks such as migrations
  """

  @app :cambiatus

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # This Remote Code Execution potential vulnerability is skipped because the file
  # beign evaluated is stored within our server. Therefore it and cannot be tampered by users

  # sobelow_skip ["RCE"]
  def seed() do
    load_app()
    seed_script = Application.app_dir(:cambiatus, "priv/repo/seeds.exs")

    IO.puts("Running seeds")
    Code.eval_file(seed_script)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
