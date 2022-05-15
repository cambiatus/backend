defmodule Cambiatus.Shop.Category do
  @moduledoc """
  Categories are used to organize products into groups

  Allows for filtering and scoping with an name, description.
  It also supports meta tags for indexing as well slugs for URL customization
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Commune.Community
  alias Cambiatus.Shop.{Category, Product, ProductCategory}

  schema "categories" do
    field(:icon, :string)
    field(:image_uri, :string)
    field(:name, :string)
    field(:description, :string)

    field(:slug, :string)
    field(:meta_title, :string)
    field(:meta_description, :string)
    field(:meta_keywords, :string)

    timestamps()

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:category, Category)

    many_to_many(:products, Product, join_through: ProductCategory)
  end

  @required_fields ~w(community_id name description slug)a
  @optional_fields ~w(category_id icon image_uri meta_title meta_description meta_keywords)a

  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
