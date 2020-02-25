defmodule Cambiatus.Repo.Migrations.CompoundIds do
  @moduledoc """
  Migration to build compound ids for checks and claims
  """
  use Ecto.Migration

  def up do
    execute("ALTER TABLE validators DROP CONSTRAINT validators_action_id_fkey")
    execute("ALTER TABLE validators DROP CONSTRAINT validators_validator_id_fkey")
    execute("ALTER TABLE checks DROP CONSTRAINT checks_claim_id_fkey")
    execute("ALTER TABLE checks DROP CONSTRAINT checks_validator_id_fkey")

    alter table(:validators) do
      remove(:id)

      modify(:action_id, references(:actions), primary_key: true)

      modify(:validator_id, references(:users, column: :account, type: :string), primary_key: true)
    end

    alter table(:checks) do
      remove(:id)

      modify(:claim_id, references(:claims), primary_key: true)

      modify(:validator_id, references(:users, column: :account, type: :string), primary_key: true)
    end
  end

  def down do
    execute("ALTER TABLE validators DROP CONSTRAINT validators_action_id_fkey")
    execute("ALTER TABLE validators DROP CONSTRAINT validators_validator_id_fkey")
    execute("ALTER TABLE checks DROP CONSTRAINT checks_claim_id_fkey")
    execute("ALTER TABLE checks DROP CONSTRAINT checks_validator_id_fkey")

    create(index(:validators, [:action_id, :validator_id]))
    create(index(:checks, [:claim_id, :validator_id, :is_verified]))
  end
end
