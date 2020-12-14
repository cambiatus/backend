defmodule Cambiatus.Repo.Migrations.RemoveAvailableSales do
  use Ecto.Migration

  def change do
    execute("""
    DROP MATERIALIZED VIEW IF EXISTS available_sales;
    """)

    execute("""
    DROP FUNCTION IF EXISTS refresh_available_sales() CASCADE;
    """)

    execute("""
    DROP TRIGGER IF EXISTS refresh_available_sales_trigger ON sales;
    """)
  end
end
