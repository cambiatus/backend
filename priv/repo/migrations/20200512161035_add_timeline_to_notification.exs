defmodule Cambiatus.Repo.Migrations.AddTimelineToNotification do
  use Ecto.Migration

  def change do
    alter table(:notification_history) do
      add(:is_in_timeline, :boolean, null: false, default: false)
    end
  end
end
