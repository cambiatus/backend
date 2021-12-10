defmodule Cambiatus.Repo.Migrations.MemberRole do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TYPE permission AS ENUM
     ('invite', 'claim', 'order', 'verify', 'sell', 'award')
    """)

    create table(:roles) do
      add(:community_id, references(:communities, column: :symbol, type: :string, null: false))

      add(:name, :string, comment: "Name of the role")
      add(:color, :string, comment: "Primary color associated with the role")

      add(:permissions, {:array, :permission},
        default: [],
        comment: "List of permissions this role is associated with"
      )

      timestamps()
    end

    create table(:network_roles) do
      add(:network_id, references(:network))
      add(:role_id, references(:roles))

      timestamps()
    end
  end

  def down do
    drop(table(:roles))
    drop(table(:network_roles))

    execute("DROP TYPE permission")
  end
end
