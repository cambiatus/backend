defmodule BeSpiral.Repo.Migrations.CreateMintTrigger do
  @moduledoc """
  Trigger to run when mints are added to the database
  """
  use Ecto.Migration

  @table "mints"
  @function "mint_added"
  @trigger "mints_modified"

  def up do
    execute("""
      CREATE TRIGGER #{@trigger}
      AFTER INSERT
      ON #{@table}
      FOR EACH ROW
      EXECUTE PROCEDURE #{@function}()
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS #{@trigger} on #{@table}")
  end
end
