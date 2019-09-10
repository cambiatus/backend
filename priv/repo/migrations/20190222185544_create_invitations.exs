defmodule BeSpiral.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add(:community, references(:communities, column: :symbol, type: :string))
      add(:inviter, references(:users, column: :account, type: :string))
      add(:invitee_email, :string, null: false)
      add(:accepted, :boolean, null: false, default: false)

      timestamps()
    end

    create(
      unique_index(:invitations, [:community, :invitee_email],
        name: :invitations_community_invitee_index
      )
    )
  end
end
