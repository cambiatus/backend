defmodule Cambiatus.Repo.Migrations.DefaultClaimIsVerified do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      modify(:is_verified, :bool, default: false)
    end
  end
end
