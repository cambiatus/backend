defmodule Cambiatus.Repo.Migrations.MultipleShopImages do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add(:inserted_at, :naive_datetime, null: true)
      add(:updated_at, :naive_datetime, null: true)
    end

    create table(:product_images) do
      add(:product_id, references(:products))
      add(:uri, :string, null: false, comment: "URI for the image or video")

      timestamps()
    end

    create(
      unique_index(:product_images, [:product_id, :uri],
        name: :product_images_unique_product_image
      )
    )
  end
end
