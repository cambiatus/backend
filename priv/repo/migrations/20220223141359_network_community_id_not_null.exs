defmodule Cambiatus.Repo.Migrations.NetworkCommunityIdNotNull do
  use Ecto.Migration

  def change do
    alter table(:network) do
      modify(:community_id, references(:communities, column: :symbol, type: :string),
        null: false,
        from: references(:communities, column: :symbol, type: :string)
      )
    end
  end
end
