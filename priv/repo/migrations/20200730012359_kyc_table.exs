defmodule Cambiatus.Repo.Migrations.KycTable do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_type As ENUM ('natural', 'juridical')")

    execute(
      "CREATE TYPE document_type As ENUM ('mipyme', 'gran_empresa', 'cedula_de_identidad', 'dimex', 'nite')"
    )

    create table(:countries) do
      add(:name, :string)

      timestamps()
    end

    create(unique_index(:countries, [:name]))

    create table(:states) do
      add(:name, :string)
      add(:country_id, references(:countries))

      timestamps()
    end

    create table(:cities) do
      add(:name, :string)
      add(:state_id, references(:states))

      timestamps()
    end

    create table(:neighborhoods) do
      add(:name, :string)
      add(:city_id, references(:cities))

      timestamps()
    end

    create table(:addresses) do
      add(:account_id, references(:users, column: :account, type: :string))
      add(:country_id, references(:countries))
      add(:state_id, references(:states))
      add(:city_id, references(:cities))
      add(:neighborhood_id, references(:neighborhoods))
      add(:street, :string, null: true)
      add(:zip, :string, null: true)
      add(:number, :string, null: true)

      timestamps()
    end

    create table(:kyc_data) do
      add(:account_id, references(:users, column: :account, type: :string))
      add(:user_type, :user_type, default: "natural")
      add(:document, :string, null: false)
      add(:document_type, :document_type, null: false)
      add(:phone, :string, null: false)
      add(:country_id, references(:countries), null: false)
      add(:is_verified, :boolean, null: false, default: false)

      timestamps()
    end
  end

  def down do
    drop(table(:kyc_data))
    drop(table(:addresses))
    drop(table(:neighborhoods))
    drop(table(:cities))
    drop(table(:states))
    drop(table(:countries))

    execute("DROP TYPE user_type")
    execute("DROP TYPE document_type")
  end
end
