defmodule Cambiatus.Repo.Migrations.CreateAuthSessions do
  use Ecto.Migration

  def change do
    create table(:auth_sessions) do
      add(:user_id, references(:users, column: :account, type: :string), null: false)
      add(:user_agent, :string, null: false, comment: "User device")
      add(:ip_address, :string)
      add(:token, :string, null: false, comment: "User session token authorization")

      timestamps()
    end
  end
end
