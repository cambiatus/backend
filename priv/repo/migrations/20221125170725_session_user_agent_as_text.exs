defmodule Cambiatus.Repo.Migrations.SessionUserAgentAsText do
  use Ecto.Migration

  def change do
    alter table(:auth_sessions) do
      modify(:user_agent, :text, null: false, comment: "User device")
    end
  end
end
