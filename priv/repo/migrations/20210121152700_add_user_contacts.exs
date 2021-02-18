defmodule Cambiatus.Repo.Migrations.AddUserContacts do
  use Ecto.Migration

  def change do
    create_query =
      "CREATE TYPE contact_type AS ENUM ('phone', 'whatsapp', 'telegram', 'instagram')"

    drop_query = "DROP TYPE contact_type"
    execute(create_query, drop_query)

    create table(:contacts) do
      add(:user_id, references(:users, column: :account, type: :string))
      add(:type, :contact_type)
      add(:external_id, :string)

      timestamps()
    end
  end
end
