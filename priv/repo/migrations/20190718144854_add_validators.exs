defmodule BeSpiral.Repo.Migrations.AddValidators do
  @moduledoc """
  Migration to build a validators table, which holds memmbers that can validate
  an actions completion
  """
  use Ecto.Migration

  def change do
    create table(:validators) do
      add(:action_id, references(:actions))
      add(:validator_id, references(:users, column: :account, type: :string))

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create(index(:validators, [:action_id, :validator_id]))
  end
end
