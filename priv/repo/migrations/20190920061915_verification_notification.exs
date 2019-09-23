defmodule BeSpiral.Repo.Migrations.VerificationNotification do
  @moduledoc """
  Database function and trigger for operations on the claim table that enables 
  us to propagate notifications for requested verifications to validators 
  """
  use Ecto.Migration

  @function "claims_notification"
  @event "claim_added"
  @table "claims"

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION #{@function}()
      RETURNS trigger AS $$
      BEGIN 
        PERFORM pg_notify(
          '#{@event}',
          json_build_object(
            'operation', TG_OP
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
      AFTER INSERT 
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
