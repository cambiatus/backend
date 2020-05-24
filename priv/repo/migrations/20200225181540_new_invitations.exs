defmodule Cambiatus.Repo.Migrations.NewInvitations do
  use Ecto.Migration

  def up do
    # Remove old invitations table
    drop(table(:invitations))

    # Define new one
    create table(:invitations) do
      add(:creator_id, references(:users, column: :account, type: :string))
      add(:community_id, references(:communities, column: :symbol, type: :string))

      timestamps()
    end
  end

  def down do
  end
end
