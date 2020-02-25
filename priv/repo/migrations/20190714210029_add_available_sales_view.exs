defmodule Cambiatus.Repo.Migrations.AddAvailableSalesView do
  use Ecto.Migration

  def up do
    execute """
    CREATE MATERIALIZED VIEW available_sales AS
      SELECT
        id,
        community_id,
        creator_id,
        title,
        description,
        price,
        image,
        is_buy,
        units,
        created_block,
        created_tx,
        created_eos_account,
        created_at
      FROM sales
      WHERE is_deleted = false
        AND units > 0;
    """

    execute """
    CREATE OR REPLACE FUNCTION refresh_available_sales()
    RETURNS trigger AS $$
    BEGIN
      REFRESH MATERIALIZED VIEW available_sales;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER refresh_available_sales_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON sales
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_available_sales();
    """
  end

  def down do
    execute """
    DROP MATERIALIZED VIEW IF EXISTS available_sales;
    """

    execute """
    DROP FUNCTION IF EXISTS refresh_available_sales() CASCADE;
    """

    execute """
    DROP TRIGGER IF EXISTS refresh_available_sales_trigger ON sales;
    """
  end
end
