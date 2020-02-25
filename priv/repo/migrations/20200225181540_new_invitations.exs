defmodule BeSpiral.Repo.Migrations.NewInvitations do
  use Ecto.Migration

  def change do
    # Remove old invitations table
    drop(table(:invitations))

    # Define new one
    create table(:invitations) do
      add(:creator_id, references(:users, column: :account, type: :string))
      add(:community_id, references(:communities, column: :symbol, type: :string))

      timestamps()
    end
  end
end
