defmodule Cambiatus.Repo.Migrations.ClaimRemoveIsVerified do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      remove(:is_verified)
    end
  end
end
