defmodule Cambiatus.Repo.Migrations.ChangeSalesStructure do
  @moduledoc """
  Migration to update sales and shop_ratings structure
  """

  use Ecto.Migration

  def change do
    alter table(:sales) do
      remove :rate

      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime
    end

    create index(:sales, [:is_deleted])

    rename table(:shop_ratings), :shop_id, to: :sale_id

    alter table(:shop_ratings) do
      modify :rating, :string
    end
  end
end
