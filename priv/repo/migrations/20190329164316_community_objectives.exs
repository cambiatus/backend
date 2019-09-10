defmodule BeSpiral.Repo.Migrations.CommunityObjectives do
  use Ecto.Migration

  def change do
    create table(:community_objectives) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:creator_id, references(:users, column: :account, type: :string))
      add(:description, :string)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:community_objective_actions) do
      add(:community_objective_id, references(:community_objectives))
      add(:creator_id, references(:users, column: :account, type: :string))
      add(:reward, :float)
      add(:verifier_reward, :float)
      add(:is_verified, :boolean)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end
  end
end
