defmodule Cambiatus.Repo.Migrations.SalesUnits do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add(:units, :integer)
    end
  end
end
