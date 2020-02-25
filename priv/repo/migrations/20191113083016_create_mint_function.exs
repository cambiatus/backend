defmodule Cambiatus.Repo.Migrations.CreateMintFunction do
  @moduledoc """
  Function to create a trigger when a mint is added to the database
  """
  use Ecto.Migration

  @function "mint_added"
  @event "mints_modified"

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
      END
      $$ LANGUAGE plpgsql;
    """)
  end

  def down do
    execute("DROP FUNCTION IF EXISTS #{@function} CASCADE")
  end
end
