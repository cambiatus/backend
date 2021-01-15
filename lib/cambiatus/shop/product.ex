defmodule Cambiatus.Shop.Product do
  @moduledoc """
  This module holds the data structure that represents an instance of a `Cambiatus.Commune.Product` use it to
  build and validate changesets for operating on a product
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  @type t :: %__MODULE__{}

  alias Cambiatus.{
    Accounts.User,
    Commune.Community,
    Shop.Product
  }

  schema "products" do
    field(:title, :string)
    field(:description, :string)
    field(:price, :float)
    field(:image, :string)
    field(:track_stock, :boolean)
    field(:units, :integer)
    field(:is_deleted, :boolean)
    field(:deleted_at, :utc_datetime)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)
  end

  @required_fields ~w(title description price image track_stock units
  created_block is_deleted deleted_at created_tx created_eos_account created_at)a

  @doc """
  This function contains the logic required for the validation of base shop changeset
  """
  @spec changeset(Product.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Product{} = shop, attrs) do
    shop
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %Product{}
    |> changeset(attrs)
    |> put_assoc(:creator, attrs.creator)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:community_id)
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

  def by_description(query \\ Product, q) do
    query
    |> where([p], p.description == ^q)
  end
end
