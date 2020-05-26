defmodule Cambiatus.Repo.Migrations.AddFeaturesTable do
  use Ecto.Migration

  def up do
    alter table("communities") do
      add(:has_actions, :boolean, default: true)
      add(:has_shop, :boolean, default: true)
    end
  end

  def down do
    alter table("communities") do
      remove(:has_actions)
      remove(:has_shop)
    end
  end
end
