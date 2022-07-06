defmodule Cambiatus.Repo.Migrations.CategoryText do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      modify(:description, :text, null: false, comment: "Markdown description of the category")
    end
  end
end
