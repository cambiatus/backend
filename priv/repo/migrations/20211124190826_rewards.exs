defmodule Cambiatus.Repo.Migrations.Rewards do
  use Ecto.Migration

  def change do
    create table(:rewards) do
      add(:action_id, references(:actions),
        null: false,
        comment: "Action this reward belongs to, its always an automatic type"
      )

      add(:receiver_id, references(:users, column: :account, type: :string),
        null: false,
        comment: "Receiver of the reward"
      )

      add(:awarder_id, references(:users, column: :account, type: :string),
        comment: "Awarder, must be an admin"
      )

      add(:amount, :float,
        null: false,
        comment: "Amount of the reward"
      )

      timestamps()
    end
  end
end
