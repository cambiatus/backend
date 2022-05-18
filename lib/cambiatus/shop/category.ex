defmodule Cambiatus.Shop.Category do
  @moduledoc """
  Categories are used to organize products into groups

  Allows for filtering and scoping with an name, description.
  It also supports meta tags for indexing as well slugs for URL customization
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.{Repo, Shop}
  alias Cambiatus.Commune.Community
  alias Cambiatus.Shop.{Category, Product, ProductCategory}

  schema "categories" do
    field(:icon_uri, :string)
    field(:image_uri, :string)
    field(:name, :string)
    field(:description, :string)

    field(:slug, :string)
    field(:meta_title, :string)
    field(:meta_description, :string)
    field(:meta_keywords, :string)

    field(:position, :integer)

    timestamps()

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:category, Category)
    has_many(:categories, Category)

    many_to_many(:products, Product, join_through: ProductCategory)
  end

  @required_fields ~w(community_id name description slug)a
  @optional_fields ~w(category_id icon_uri image_uri meta_title meta_description meta_keywords position)a

  def changeset(%Category{} = category, attrs) do
    category
    |> Repo.preload(:categories)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> Shop.validate_community_shop_enabled()
    |> assoc_categories(attrs)
  end

  def assoc_categories(changeset, %{categories: []}), do: changeset

  def assoc_categories(changeset, %{categories: _} = attrs) do
    put_assoc(changeset, :categories, Map.get(attrs, :categories))
  end

  def assoc_categories(changeset, _), do: changeset
end
