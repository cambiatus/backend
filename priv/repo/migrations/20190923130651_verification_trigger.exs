defmodule Cambiatus.Repo.Migrations.VerificationTrigger do
  @moduledoc """
  Trigger to run when claims are added to the database
  """
  use Ecto.Migration

  @table "claims"
  @function "verification_notification"
  @trigger "claims_changed"

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
