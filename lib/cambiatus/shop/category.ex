defmodule Cambiatus.Shop.Category do
  @moduledoc """
  Categories are used to organize products into groups

  Allows for filtering and scoping with an name, description.
  It also supports meta tags for indexing as well slugs for URL customization
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

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

    timestamps()

    belongs_to(:community, Community, references: :symbol, type: :string)
    field(:position, :integer)

    belongs_to(:parent, Category)

    has_many(:categories, Category,
      foreign_key: :parent_id,
      on_delete: :delete_all,
      on_replace: :nilify
    )

    many_to_many(:products, Product, join_through: ProductCategory)
  end

  @required_fields ~w(community_id name description slug position)a
  @optional_fields ~w(id parent_id icon_uri image_uri meta_title meta_description meta_keywords)a

  def changeset(%Category{} = category, attrs) do
    category
    |> Repo.preload(:categories)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> Shop.validate_community_shop_enabled()
    |> validate_position()
    |> validate_root_position(category)
  end

  def assoc_categories(changeset, []), do: changeset

  def assoc_categories(changeset, categories) do
    put_assoc(changeset, :categories, categories)
  end

  def validate_position(changeset) do
    position = get_field(changeset, :position)

    if position < 0 do
      add_error(changeset, :position, "position cant be negative")
    else
      changeset
    end
  end

  def validate_root_position(changeset, %{id: _, community_id: community_id}) do
    position = get_field(changeset, :position)

    # TODO: Remove this
    IO.inspect(changeset)

    # Only checks this if it is a root category's position
    count =
      Category
      |> where([c], c.community_id == ^community_id)
      |> where([c], is_nil(c.parent_id))
      |> Repo.aggregate(:count, :id)

    IO.puts("Position é #{position}, count é #{count}")

    if position >= count do
      add_error(changeset, :position, "isn't valid")
    else
      changeset
    end
  end

  def validate_root_position(changeset, _), do: changeset

  def positional(query \\ Category) do
    order_by(query, [c], asc: :position)
  end
end
