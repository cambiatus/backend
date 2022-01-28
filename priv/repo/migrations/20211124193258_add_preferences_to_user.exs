defmodule Cambiatus.Repo.Migrations.AddPreferencesToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:language, :string, null: false, default: "en-US")
      add(:transfer_notification, :boolean, null: false, default: false)
      add(:claim_notification, :boolean, null: false, default: false)
      add(:digest, :boolean, null: false, default: false)
    end
  end
end
