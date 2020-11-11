defmodule Cambiatus.Repo.Migrations.ObjectiveCompletion do
  use Ecto.Migration

  def change do
    alter table(:objectives) do
      add(:is_completed, :boolean, default: false, nullable: false)
      add(:completed_at, :naive_datetime, default: nil)
    end
  end
end
