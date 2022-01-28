defmodule Cambiatus.Repo.Migrations.IncreaseBioSize do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:bio, :text)
    end
  end
end
