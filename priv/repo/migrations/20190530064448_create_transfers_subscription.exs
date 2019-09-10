defmodule BeSpiral.Repo.Migrations.CreateTransfersSubscription do
  @moduledoc """
  Function and trigger fot transfer table operations
  """
  use Ecto.Migration

  @function "transfers_notification"
  @event "transfers_changed"
  @table "transfers"

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION #{@function}()
      RETURNS trigger AS $$
      BEGIN
        PERFORM pg_notify(
          '#{@event}',
          json_build_object(
            'operation', TG_OP,
            'record', row_to_json(NEW)
            )::text
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("DROP TRIGGER IF EXISTS #{@event} ON #{@table}")

    execute("""
      CREATE TRIGGER #{@event}
      AFTER INSERT OR UPDATE
      ON #{@table}
      FOR EACH ROW
      EXECUTE PROCEDURE #{@function}()
    """)
  end

  def down do
    execute("DROP FUNCTION IF EXISTS #{@function} CASCADE")

    execute("DROP TRIGGER IF EXISTS #{@event} ON #{@table}")
  end
end
