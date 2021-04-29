defmodule Cambiatus.Repo.Migrations.AddPhotosAndWebsite do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:website, :string)
    end

    create table(:photos) do
      add(:url, :string)

      add(:user_id, references(:users, column: :account, type: :string))
      timestamps()
    end
  end
end
