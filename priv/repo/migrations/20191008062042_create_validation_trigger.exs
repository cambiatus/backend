defmodule Cambiatus.Repo.Migrations.CreateValidationTrigger do
  @moduledoc """
  Trigger to run when checks are added to the database
  """
  use Ecto.Migration

  @table "checks"
  @function "validation_notification"
  @trigger "check_added"

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
    execute("DROP TRIGGER IF EXISTS #{@trigger} ON #{@table}")
  end
end
