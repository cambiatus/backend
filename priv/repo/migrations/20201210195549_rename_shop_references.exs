defmodule Cambiatus.Repo.Migrations.RenameShopReferences do
  use Ecto.Migration

  def change do
    rename(table("orders"), :sale_id, to: :product_id)
  end
end
