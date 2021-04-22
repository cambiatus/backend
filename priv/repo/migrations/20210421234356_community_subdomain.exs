defmodule Cambiatus.Repo.Migrations.CommunitySubdomain do
  use Ecto.Migration

  def up do
    alter table(:communities) do
      remove(:precision)
      add(:subdomain, :string)
      # add(:subdomain, references(:subdomains, column: :name, type: :string, null: true))
    end
  end

  def down do
    alter table(:communities) do
      add(:precision, :integer)
      remove(:subdomain)
    end
  end
end
