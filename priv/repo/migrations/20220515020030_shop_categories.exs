defmodule Cambiatus.Repo.Migrations.ShopCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:community_id, references(:communities, column: :symbol, type: :string, null: false))
      add(:category_id, references(:categories))

      add(:icon, :string, null: false, comment: "URI for the icon")
      add(:image, :string, null: false, comment: "URI for the image")
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

      timestamps()
    end

    create table(:product_categories) do
      add(:product_id, references(:products))
      add(:category_id, references(:categories))
      add(:position, :integer, null: false, comment: "Ordering position")

      timestamps()
    end
  end
end
