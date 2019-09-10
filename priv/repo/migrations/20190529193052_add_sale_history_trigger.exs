defmodule BeSpiral.Repo.Migrations.AddSaleHistoryTrigger do
  use Ecto.Migration

  @table "sale_history"
  @trigger "sale_history_changed"
  @function "sale_history_notification"

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
