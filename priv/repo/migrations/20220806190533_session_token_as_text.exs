defmodule Cambiatus.Repo.Migrations.SessionTokenAsText do
  use Ecto.Migration

  def change do
    alter table(:auth_sessions) do
      modify(:token, :text, null: false, comment: "Markdown description of the category")
    end
  end
end
