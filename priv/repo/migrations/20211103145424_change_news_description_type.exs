defmodule Cambiatus.Repo.Migrations.ChangeNewsDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:news) do
      modify(:description, :text)
    end

    alter table(:news_versions) do
      modify(:description, :text)
    end
  end
end
