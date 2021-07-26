defmodule Cambiatus.Repo.Migrations.MakeSubdomainIdNonNull do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      modify(:subdomain_id, :int, null: false)
    end
  end
end
