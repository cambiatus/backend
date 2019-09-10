defmodule BeSpiral.Repo.Migrations.CreateSalesNotificationFunction do
  @moduledoc """
  Defines a Notification function that will create a trigger for operations to the sales table
  """
  use Ecto.Migration

  @function "sales_notification"
  @event "sales_changed"

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
