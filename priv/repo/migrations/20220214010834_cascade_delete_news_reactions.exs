defmodule Cambiatus.Repo.Migrations.CascadeDeleteNewsReactions do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE news_receipts DROP CONSTRAINT news_receipts_news_id_fkey")

    alter table(:news_receipts) do
      modify(:news_id, references(:news, on_delete: :delete_all))
    end
  end

  def down do
    execute("ALTER TABLE news_receipts DROP CONSTRAINT news_receipts_news_id_fkey")

    alter table(:news_receipts) do
      modify(:news_id, references(:news, on_delete: :nothing))
    end
  end
end
