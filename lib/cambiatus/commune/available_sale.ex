defmodule Cambiatus.Commune.AvailableSale do
  @moduledoc """
  This module holds the data structure that represents an instance of a `Cambiatus.Commune.AvailableSale` use it to
  build and validate changesets for reading an available sale
  """
  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias Cambiatus.{
    Accounts.User,
    Commune.Community,
    Commune.AvailableSale
  }

  schema "available_sales" do
    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)
    field(:title, :string)
    field(:description, :string)
    field(:price, :float)
    field(:image, :string)
    field(:track_stock, :boolean)
    field(:units, :integer)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end

  @required_fields ~w(title description price image track_stock
  units created_block created_tx created_eos_account created_at)a

  @doc """
  This function contains the logic required for the validation of base shop changeset
  """
  @spec changeset(AvailableSale.t(), map()) :: Ecto.Changeset.t()
  def changeset(%AvailableSale{} = shop, attrs) do
    shop
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %AvailableSale{}
    |> changeset(attrs)
    |> put_assoc(:creator, attrs.creator)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:community_id)
  end
end
