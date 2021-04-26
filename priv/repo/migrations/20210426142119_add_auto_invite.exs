defmodule Cambiatus.Repo.Migrations.AddAutoInvite do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:auto_invite, :boolean, default: false)
    end
  end
end
