defmodule Cambiatus.Repo.Migrations.Subdomains do
  use Ecto.Migration

  def change do
    create table(:subdomains) do
      add(:name, :string)

      timestamps()
    end

    create(unique_index(:subdomains, [:name]))
  end
end
