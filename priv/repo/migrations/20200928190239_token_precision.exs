defmodule Cambiatus.Repo.Migrations.TokenPrecision do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:precision, :integer, default: 0)
    end
  end
end
