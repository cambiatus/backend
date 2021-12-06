defmodule Cambiatus.Repo.Migrations.AddPreferencesToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:language, :string)
      add(:transfer_notification, :boolean)
      add(:claim_notification, :boolean)
      add(:digest, :boolean)
    end
  end
end
