defmodule Cambiatus.Repo.Migrations.AddIndexToCreatedAtInTransfers do
  use Ecto.Migration

  def change do
    create index(:transfers, [:created_at])
  end
end
