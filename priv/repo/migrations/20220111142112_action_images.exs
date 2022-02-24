defmodule Cambiatus.Repo.Migrations.ActionImages do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      add(:image, :string, default: nil)
    end
  end
end
