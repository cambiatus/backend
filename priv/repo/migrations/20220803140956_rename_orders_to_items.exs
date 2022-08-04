defmodule Cambiatus.Repo.Migrations.RenameOrdersToItems do
  use Ecto.Migration

  def change do
    rename(table(:orders), to: table(:items))
  end
end
