defmodule Cambiatus.Repo.Migrations.CreateSalesNotificationTrigger do
  @moduledoc """
  Defines a trigger to publish events for operations on the sales table
  """
  use Ecto.Migration

  @table "sales"
  @function "sales_notification"
  @trigger "sales_changed"

  def up do
    execute("DROP TRIGGER IF EXISTS #{@trigger} ON #{@table}")

    execute("""
      CREATE TRIGGER #{@trigger}
      AFTER INSERT OR UPDATE
      ON #{@table}
      FOR EACH ROW
      EXECUTE PROCEDURE #{@function}()
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS #{@trigger} ON #{@table}")
  end
end
