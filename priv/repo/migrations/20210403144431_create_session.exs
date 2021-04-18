defmodule Cambiatus.Repo.Migrations.CreateSession do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE context_type AS ENUM ('auth', 'session')"

    drop_query = "DROP TYPE context_type"
    execute(create_query, drop_query)

    create table(:user_tokens) do
      add(:user_id, references(:users, column: :account, type: :string, on_delete: :delete_all),
        null: false
      )

      add(:phrase, :string)
      add(:token, :binary)
      add(:context, :context_type, null: false)

      timestamps(updated_at: false)
    end

    create(unique_index(:user_tokens, [:user_id, :context], name: :unique_context))
  end
end
