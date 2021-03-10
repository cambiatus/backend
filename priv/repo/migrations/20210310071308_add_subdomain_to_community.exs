defmodule Cambiatus.Repo.Migrations.AddSubdomainToCommunity do
  use Ecto.Migration

  def change do
    alter table("communities") do
      add(:subdomain, :string, null: true)
    end

    create unique_index(:communities, [:subdomain])
  end
end
