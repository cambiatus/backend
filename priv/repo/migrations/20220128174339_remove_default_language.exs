defmodule Cambiatus.Repo.Migrations.RemoveDefaultLanguage do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove(:language)
      add(:language, :string)
    end
  end

  def down do
  end
end
