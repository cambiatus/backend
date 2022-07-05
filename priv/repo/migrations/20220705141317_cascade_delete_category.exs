defmodule Cambiatus.Repo.Migrations.CascadeDeleteCategory do
  use Ecto.Migration

  def up do
    drop(constraint(:categories, "categories_parent_id_fkey"))

    alter table(:categories) do
      modify(:parent_id, references(:categories, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:categories, "categories_parent_id_fkey"))

    alter table(:categories) do
      modify(:parent_id, references(:categories, on_delete: :nothing))
    end
  end
end
