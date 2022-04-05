defmodule Cambiatus.Repo.Migrations.MultipleShopImages do
  use Ecto.Migration

  def change do
    alter table(:products) do
      timestamps()
    end

    create table(:product_images) do
      add(:product_id, references(:products))
      add(:uri, :string, null: false, comment: "URI for the image or video")

      timestamps()
    end
  end
end
