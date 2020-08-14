defmodule Cambiatus.Repo.Migrations.AddKycFeatureCommunities do
  use Ecto.Migration

  def change do
    alter table("communities") do
      add(:has_kyc, :boolean, default: false)
    end
  end
end
