defmodule Cambiatus.Repo.Migrations.AddFeaturesTable do
  use Ecto.Migration

  def up do
    create table("features") do
      add(:actions, :boolean, default: true)
      add(:shop, :boolean, default: true)
      add(:community_id, :string)

      timestamps()
    end
  end

  def down do
    drop(table("features"))
  end
end
