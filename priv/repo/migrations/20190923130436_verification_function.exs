defmodule Cambiatus.Repo.Migrations.VerificationFunction do
  @moduledoc """
  Function to create trigger when claims are added to the database
  """
  use Ecto.Migration

  @function "verification_notification"
  @event "claims_changed"

  def up do
    # Remove botched former migration
    execute("DROP FUNCTION IF EXISTS #{@function} CASCADE")

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
  end

  def down do
    execute("DROP FUNCTION IF EXISTS #{@function} CASCADE")
  end
end
