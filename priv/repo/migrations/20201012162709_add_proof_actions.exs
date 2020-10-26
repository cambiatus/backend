defmodule Cambiatus.Repo.Migrations.AddProofActions do
  use Ecto.Migration

  def change do
    alter table("actions") do
      add(:has_proof_photo, :boolean, default: false)
      add(:has_proof_code, :boolean, default: false)
      add(:photo_proof_instructions, :string, null: true)
    end

    alter table("claims") do
      add(:proof_photo, :string, null: true)
      add(:proof_code, :string, null: true)
    end
  end
end
