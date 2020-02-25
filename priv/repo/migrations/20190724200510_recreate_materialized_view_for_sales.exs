defmodule Cambiatus.Repo.Migrations.RecreateMaterializedViewForSales do
  @moduledoc """
  Migration to recreate the available_sales materialized view with track_stock
  """
  use Ecto.Migration

  def up do
    execute """
    DROP MATERIALIZED VIEW IF EXISTS available_sales;
    """

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
        track_stock,
        units,
        created_block,
        created_tx,
        created_eos_account,
        created_at
      FROM sales
      WHERE is_deleted = false
    """
  end

  def down do
    execute """
    DROP MATERIALIZED VIEW IF EXISTS available_sales;
    """
  end
end
