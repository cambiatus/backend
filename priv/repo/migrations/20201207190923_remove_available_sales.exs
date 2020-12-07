defmodule Cambiatus.Repo.Migrations.RemoveAvailableSales do
  use Ecto.Migration

  def change do
    execute("DROP MATERIALIZED VIEW available_sales")
  end
end
