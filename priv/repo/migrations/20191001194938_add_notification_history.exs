defmodule BeSpiral.Repo.Migrations.AddNotificationHistory do
  use Ecto.Migration

  def change do
    create table(:notification_history) do
      add(:recipient_id, references(:users, column: :account, type: :string))
      add(:type, :string, null: false)
      add(:payload, :json, null: false)
      add(:is_read, :boolean, null: false, default: false)

      timestamps()
    end
  end
end
