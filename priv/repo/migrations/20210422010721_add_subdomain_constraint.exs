defmodule Cambiatus.Repo.Migrations.AddSubdomainConstraint do
  use Ecto.Migration

  def up do
    alter table(:communities) do
      modify(:subdomain, references(:subdomains, column: :name, type: :string, null: true))
    end
  end

  def down do
    drop(constraint(:communities, :communities_subdomain_fkey))

    alter table(:communities) do
      modify(:subdomain, :string)
    end
  end
end
