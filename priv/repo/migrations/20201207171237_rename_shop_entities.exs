defmodule Cambiatus.Repo.Migrations.RenameShopEntities do
  use Ecto.Migration

  def change do
    rename(table(:sales), to: table(:products))
    rename(table(:sale_history), to: table(:orders))
  end
end
