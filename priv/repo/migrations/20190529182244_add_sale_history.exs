defmodule Cambiatus.Repo.Migrations.AddSaleHistory do
  @moduledoc """
  Adds Sale history table
  """

  use Ecto.Migration

  @function "sale_history_notification"
  @event "sale_history_changed"

  def up do
    create table(:sale_history) do
      add(:sale_id, references(:sales))
      add(:from_id, references(:users, column: :account, type: :string))
      add(:to, references(:users, column: :account, type: :string))
      add(:quantity, :float)
      add(:units, :integer)
    end

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
    drop(table(:sale_history))
  end
end
