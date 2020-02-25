defmodule Cambiatus.Repo.Migrations.AddTrackStockToSalesTable do
  @moduledoc """
  Migration to add track_stock field to sales table
  """
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add :track_stock, :boolean, default: true, null: false
    end
  end
end
