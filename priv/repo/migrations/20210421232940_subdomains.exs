defmodule Cambiatus.Repo.Migrations.Subdomains do
  use Ecto.Migration

  def change do
    create table(:subdomains, primary_key: false) do
      add(:name, :string, primary_key: true)

      timestamps()
    end
  end
end
