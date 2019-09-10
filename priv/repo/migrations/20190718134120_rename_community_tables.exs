defmodule BeSpiral.Repo.Migrations.RenameCommunityTables do
  use Ecto.Migration

  def change do
    rename(table(:community_objectives), to: table(:objectives))

    rename(table(:community_mints), to: table(:mints))

    rename(table(:community_objective_actions), to: table(:actions))

    rename(table(:community_expiry_options), to: table(:expiry_options))
  end
end
