defmodule Cambiatus.Repo.Migrations.NewsReceiptsUserIdNewsIdIndex do
  use Ecto.Migration

  def change do
    create(unique_index(:news_receipts, [:user_id, :news_id]))
  end
end
