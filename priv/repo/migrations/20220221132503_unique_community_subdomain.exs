defmodule Cambiatus.Repo.Migrations.UniqueCommunitySubdomain do
  use Ecto.Migration

  def change do
    create(unique_index(:communities, [:subdomain_id]))
  end
end
