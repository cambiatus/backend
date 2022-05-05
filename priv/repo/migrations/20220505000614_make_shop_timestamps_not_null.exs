defmodule Cambiatus.Repo.Migrations.MakeShopTimestampsNotNull do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify(:inserted_at, :naive_datetime, null: false)
      modify(:updated_at, :naive_datetime, null: false)
    end
  end
end
