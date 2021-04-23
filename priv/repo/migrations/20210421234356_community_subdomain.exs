defmodule Cambiatus.Repo.Migrations.CommunitySubdomain do
  use Ecto.Migration

  def up do
    alter table(:communities) do
      remove(:precision)
      add(:subdomain_id, references(:subdomains))
    end
  end

  def down do
    alter table(:communities) do
      add(:precision, :integer)
      remove(:subdomain_id)
    end
  end
end
