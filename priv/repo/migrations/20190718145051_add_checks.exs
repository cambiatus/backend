defmodule BeSpiral.Repo.Migrations.AddChecks do
  @moduledoc """
  Migration to add a checks table that contains, validation checks on actions 
  """
  use Ecto.Migration

  def change do
    create table(:checks) do
      add(:is_verified, :boolean, default: false)
      add(:claim_id, references(:claims))
      add(:validator_id, references(:users, column: :account, type: :string))

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create(index(:checks, [:claim_id, :validator_id, :is_verified]))
  end
end
