defmodule BeSpiral.Repo.Migrations.CommunityIssue do
  use Ecto.Migration

  def change do
    create table(:community_mints) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:to_id, references(:users, column: :account, type: :string))
      add(:quantity, :float)
      add(:memo, :string)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end
  end
end
