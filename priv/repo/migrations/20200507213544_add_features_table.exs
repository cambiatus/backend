defmodule Cambiatus.Repo.Migrations.AddFeaturesTable do
  use Ecto.Migration

  def up do
    alter table("communities") do
      add(:actions, :boolean, default: true)
      add(:shop, :boolean, default: true)
    end
  end

  def down do
    alter table("communities") do
      remove(:actions)
      remove(:shop)
    end
  end
end
