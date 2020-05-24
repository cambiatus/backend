defmodule Cambiatus.Repo.Migrations.ClaimStatus do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE claim_status AS ENUM ('pending', 'approved', 'rejected')")

    alter table(:claims) do
      add(:status, :claim_status, null: false, default: "pending")
      # remove(:is_verified)
    end
  end

  def down do
    alter table(:claims) do
      # remove(:status)
      add(:is_verified, :bool, default: false)
    end

    execute("DROP TYPE claim_status")
  end
end
