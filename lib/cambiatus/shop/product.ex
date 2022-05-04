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
    field(:track_stock, :boolean)
    field(:units, :integer)
    field(:is_deleted, :boolean)
    field(:deleted_at, :utc_datetime)

    timestamps()

    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)

    has_many(:orders, Order, foreign_key: :product_id)

    has_many(:images, ProductImage,
      on_replace: :delete,
      on_delete: :delete_all
    )
  end

  @required_fields ~w(title description price track_stock community_id)a
  @optional_fields ~w(units deleted_at is_deleted creator_id inserted_at updated_at)a

  @doc """
  This function contains the logic required for the validation of base shop changeset
  """
  @spec changeset(Product.t(), map(), atom()) :: Ecto.Changeset.t()
  def changeset(product, attrs, operation \\ :create)

  def changeset(%Product{}, attrs, :create) do
    %Product{}
    |> Repo.preload(:images)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> assoc_images(attrs)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:community_id)
    |> validate_community_shop_enabled()
    |> validate_track_stock_units()
  end

  def changeset(%Product{} = product, attrs, :update) do
    product
    |> Repo.preload(:images)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> assoc_images(attrs)
    |> validate_community_shop_enabled()
    |> validate_track_stock_units()
  end

  def changeset(%Product{} = product, _, :delete) do
    product
    |> cast(%{deleted_at: DateTime.utc_now(), is_deleted: true}, [:deleted_at, :is_deleted])
  end

  def assoc_images(changeset, attrs) do
    if Map.has_key?(attrs, :images) do
      images =
        attrs
        |> Map.get(:images)
        |> Enum.map(&%ProductImage{uri: &1})

      put_assoc(changeset, :images, images)
    else
      changeset
    end
  end

  def validate_community_shop_enabled(changeset) do
    changeset
    |> get_field(:community_id)
    |> Commune.get_community()
    |> case do
      {:ok, community} ->
        if Map.get(community, :has_shop),
          do: changeset,
          else: add_error(changeset, :community_id, "shop is not enabled")

      {:error, _} ->
        add_error(changeset, :community_id, "does not exist")
    end
  end

  def validate_track_stock_units(changeset) do
    track_stock = get_field(changeset, :track_stock)
    units = get_field(changeset, :units)

    if (is_nil(track_stock) or track_stock == false) and
         (not is_nil(units) and units > 0) do
      add_error(changeset, :units, "cannot be filled if track_stock is false")
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
    |> order_by([p], desc: p.inserted_at)
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
