defmodule Cambiatus.Repo.Migrations.CreateNotificationHistoryTrigger do
  @moduledoc """
  Trigger to run when checks are added to the database
  """
  use Ecto.Migration

  @table "notification_history"
  @function "notifications_modified"
  @trigger "notifications_updated"

  def up do
    execute("""
      CREATE TRIGGER #{@trigger}
      AFTER INSERT OR UPDATE 
      ON #{@table}
      FOR EACH ROW
      EXECUTE PROCEDURE #{@function}()
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS #{@trigger} on #{@table}")
  end
end
