defmodule Cambiatus.Repo.Migrations.KycTable do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_type As ENUM ('natural', 'juridical')")

    execute(
      "CREATE TYPE document_type As ENUM ('mipyme', 'gran_empresa', 'cedula_de_identidad', 'dimex', 'nite')"
    )

    execute("CREATE TYPE country As ENUM ('costarica')")

    create table(:addresses) do
      add(:account_id, references(:users, column: :account, type: :string))
      add(:country, :country, null: true)
      add(:street, :string, null: true)
      add(:neighborhood, :string, null: true)
      add(:city, :string, null: true)
      add(:state, :string, null: true)
      add(:zip, :string, null: true)
      add(:number, :string, null: true)

      timestamps()
    end

    create table(:kyc) do
      add(:account_id, references(:users, column: :account, type: :string))
      add(:user_type, :user_type, default: "natural")
      add(:document, :string, null: false)
      add(:document_type, :document_type, null: false)
      add(:phone, :string, null: false)
      add(:country, :country, null: false)
      add(:is_verified, :boolean, null: false, default: false)
    end
  end

  def down do
    drop(table(:kyc))
    drop(table(:addresses))

    execute("DROP TYPE user_type")
    execute("DROP TYPE document_type")
    execute("DROP TYPE country")
  end
end
