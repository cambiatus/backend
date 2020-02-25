defmodule Cambiatus.Commune.Sale do
  @moduledoc """
  This module holds the data structure that represents an instance of a `Cambiatus.Commune.Sale` use it to
  build and validate changesets for operating on a sale
  """
  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias Cambiatus.{
    Accounts.User,
    Commune.Community,
    Commune.Sale
  }

  schema "sales" do
    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)
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
  end

  @required_fields ~w(title description price image track_stock units
  created_block is_deleted deleted_at created_tx created_eos_account created_at)a

  @doc """
  This function contains the logic required for the validation of base shop changeset
  """
  @spec changeset(Sale.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Sale{} = shop, attrs) do
    shop
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %Sale{}
    |> changeset(attrs)
    |> put_assoc(:creator, attrs.creator)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:community_id)
  end
end
