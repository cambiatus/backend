defmodule BeSpiral.Repo.Migrations.NewCommunityTrigger do
  @moduledoc """
  Trigger to run when a community is added to the database
  """
  use Ecto.Migration

  @table "communities"
  @function "new_community"
  @trigger "community_created"

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
    execute("DROP TRIGGER IF EXISTS #{@trigger} ON #{@table}")
  end
end
