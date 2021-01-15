defmodule Cambiatus.Repo.Migrations.AddActionOrdering do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      add(:position, :integer)
    end
  end
end
