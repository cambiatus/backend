defmodule Cambiatus.Shop.Product do
  @moduledoc """
  This module holds the data structure that represents an instance of a `Cambiatus.Commune.Product` use it to
  build and validate changesets for operating on a product
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  @type t :: %__MODULE__{}

  alias Cambiatus.{Accounts.User, Commune, Repo}
  alias Cambiatus.Commune.Community
  alias Cambiatus.Shop.{Order, Product, ProductImage}

  schema "products" do
    field(:title, :string)
    field(:description, :string)
    field(:price, :float)
    field(:image, :string)
    field(:track_stock, :boolean)
    field(:units, :integer)
    field(:is_deleted, :boolean)
    field(:deleted_at, :utc_datetime)

    timestamps()

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)

    has_many(:images, ProductImage)
    has_many(:orders, Order, foreign_key: :product_id)
  end

  # TODO: Put back this after the update of structure from blockchain to graphql
  # @required_fields ~w(title description price track_stock units created_block is_deleted)a
  @required_fields ~w(title description price track_stock units created_block is_deleted created_tx created_eos_account created_at inserted_at updated_at)a
  @optional_fields ~w(deleted_at image)a

  @doc """
  This function contains the logic required for the validation of base shop changeset
  """
  @spec changeset(Product.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Product{} = shop, attrs) do
    shop
    |> Repo.preload(:images)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:images)
    |> validate_required(@required_fields)
    |> validate_community_shop_enabled()
    |> validate_track_stock_units()
  end

  def create_changeset(attrs) do
    %Product{}
    |> changeset(attrs)
    |> put_assoc(:creator, attrs.creator)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:community_id)
    |> validate_community_shop_enabled()
    |> validate_track_stock_units()
    |> validate_price_precision()
  end

  def validate_community_shop_enabled(changeset) do
    community_id = get_field(changeset, :community_id)

    Commune.get_community(community_id)
    |> case do
      {:ok, community} ->
        if Map.get(community, :has_shop),
          do: changeset,
          else: add_error(changeset, :community_id, "news is not enabled")

      {:error, _} ->
        add_error(changeset, :community_id, "does not exist")
    end
  end

  def validate_track_stock_units(changeset) do
    unless get_field(changeset, :track_stock) do
      add_error(changeset, :units, "cannot be filled if track_stock is false")
    else
      changeset
    end
  end

  def validate_token_precision(changeset) do
    community_id = get_field(changeset, :community_id)
    price = get_field(changeset, :price)
    {precision, _} = Eos.parse_symbol(community_id)

    unless Float.round(price, precision) == price do
      add_error(changeset, :price, "Price must have precision of #{precision}")
    else
      changeset
    end
  end

  def from_community(query \\ Product, community_id) do
    query
    |> where([p], p.community_id == ^community_id)
  end

  def created_by(query \\ Product, account) do
    query
    |> where([p], p.creator_id == ^account)
  end

  def active(query \\ Product) do
    query
    |> where([p], p.is_deleted == false)
  end

  def newer_first(query \\ Product) do
    query
    |> order_by([p], desc: p.created_at)
  end

  def in_stock(query \\ Product, in_stock?) do
    if in_stock? do
      where(query, [p], p.track_stock == false or (p.track_stock == true and p.units > 0))
    else
      where(query, [p], p.track_stock == true and p.units <= 0)
    end
  end

  def search(query \\ Product, q) do
    query
    |> where([p], fragment("?.description @@ plainto_tsquery(?) ", p, ^q))
    |> or_where([p], fragment("?.title @@ plainto_tsquery(?)", p, ^q))
    |> or_where([p], ilike(p.title, ^"%#{q}%"))
    |> or_where([p], ilike(p.description, ^"%#{q}%"))
  end
end
