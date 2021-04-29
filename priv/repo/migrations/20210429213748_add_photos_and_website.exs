defmodule Cambiatus.Repo.Migrations.AddPhotosAndWebsite do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:website, :string)
    end

    create table(:photos) do
      add(:url, :string, null: false)

      add(:user_id, references(:users, column: :account, type: :string))
      timestamps()
    end

    create table(:communities_photos) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:photo_id, references(:photos))

      timestamps()
    end

    create unique_index(:communities_photos, [:community_id, :photo_id])
  end
end
