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

  def changeset(%__MODULE__{} = category, attrs) do
    category
    |> Repo.preload(:categories)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> Shop.validate_community_shop_enabled()
    |> validate_position()
    |> validate_root_position()
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

  # Do nothing if there is a parent
  def validate_root_position(%{changes: %{parent_id: _}} = changeset), do: changeset

  # When inserting
  def validate_root_position(
        %{changes: %{community_id: community_id, position: position}} = changeset
      ) do
    count = Shop.count_categories(community_id)

    if position > count + 1 do
      add_error(
        changeset,
        :position,
        "for new categories, position must be smaller or equal than #{count + 1}"
      )
    else
      changeset
    end
  end

  # When updating
  def validate_root_position(
        %{
          data: %{id: id, community_id: community_id},
          changes: %{position: position}
        } = changeset
      )
      when not is_nil(id) do
    count = Shop.count_categories(community_id)

    if position > count do
      add_error(
        changeset,
        :position,
        "for existing categories, position must be smaller or equal than #{count}"
      )
    else
      changeset
    end
  end

  def validate_root_position(changeset), do: changeset

  def from_community(query \\ __MODULE__, community_id) do
    where(query, [cat], cat.community_id == ^community_id)
  end

  def roots(query \\ __MODULE__) do
    where(query, [cat], is_nil(cat.parent_id))
  end

  def between_positions(query \\ __MODULE__, p_1, p_2) do
    query =
      if p_2 > p_1 do
        where(query, [cat], cat.position <= ^p_2 and cat.position > ^p_1)
      else
        where(query, [cat], cat.position < ^p_1 and cat.position >= ^p_2)
      end

    positional(query)
  end

  def positional(query \\ __MODULE__) do
    order_by(query, [c], asc: :position)
  end
end
