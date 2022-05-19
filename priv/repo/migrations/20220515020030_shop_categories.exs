defmodule Cambiatus.Repo.Migrations.ShopCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:community_id, references(:communities, column: :symbol, type: :string, null: false))
      add(:category_id, references(:categories))

      add(:icon_uri, :string, null: true, comment: "URI for the icon")
      add(:image_uri, :string, null: true, comment: "URI for the image")
      add(:name, :string, null: false, comment: "Name")
      add(:description, :string, null: false, comment: "Markdown description of the category")

      add(:slug, :string, null: false, comment: "Slug used to match URL with rich preview")
      add(:meta_title, :string, false: true, comment: "Meta tag for title, used for indexing")

      add(:meta_description, :string,
        false: true,
        comment: "Meta tag for description, used for indexing"
      )

      add(:meta_keywords, :string,
        false: true,
        comment: "Meta tag for keywords, used for indexing"
      )

      add(:position, :integer, comment: "Ordering position")

      timestamps()
    end

    create(index(:categories, [:community_id]))
    create(index(:categories, [:category_id]))

    create table(:product_categories) do
      add(:product_id, references(:products, null: false))
      add(:category_id, references(:categories, null: false))
      add(:position, :integer, comment: "Ordering position")

      timestamps()
    end

    create(unique_index(:product_categories, [:product_id, :category_id]))
    create(unique_index(:product_categories, [:category_id, :product_id]))
  end
end
