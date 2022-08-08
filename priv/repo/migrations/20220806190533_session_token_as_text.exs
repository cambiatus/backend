defmodule Cambiatus.Repo.Migrations.SessionTokenAsText do
  use Ecto.Migration

  def change do
    alter table(:auth_sessions) do
      modify(:token, :text, null: false, comment: "User session token authorization")
    end
  end
end
