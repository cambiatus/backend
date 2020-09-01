defmodule Cambiatus.Repo.Migrations.UniqueNetwork do
  use Ecto.Migration

  def change do
    create(
      unique_index(:network, [:account_id, :community_id], name: :network_account_community_index)
    )
  end
end
