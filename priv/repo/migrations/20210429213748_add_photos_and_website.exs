defmodule Cambiatus.Repo.Migrations.AddPhotosAndWebsite do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:website, :string)
    end

    create table(:communities_photos) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:url, :string, null: false)

      timestamps()
    end

    create(unique_index(:communities_photos, [:community_id, :url]))
  end
end
