defmodule Cambiatus.Repo.Migrations.CreateValidationFunction do
  @moduledoc """
  Function to create a trigger when a claim validation is added to the database
  """
  use Ecto.Migration

  @function "validation_notification"
  @event "check_added"

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
  end

  def down do
    execute("DROP FUNCTION IF EXISTS #{@function} CASCADE")
  end
end
