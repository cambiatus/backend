defmodule BeSpiral.Commune.Transfer do
  @moduledoc """
  This module holds the data structure for transfers made in the commune context
  """

  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias BeSpiral.{
    Accounts.User,
    Commune.Community,
    Commune.Transfer
  }

  schema "transfers" do
    field(:amount, :float)
    field(:memo, :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:from, User, references: :account, type: :string)
    belongs_to(:to, User, references: :account, type: :string)
    belongs_to(:community, Community, references: :symbol, type: :string)
  end

  @required_fields ~w(amount memo created_block created_tx created_eos_account)a

  @doc """
  This function takes a Tranfer and a map of parameters and proceeeds to build a changeset for the transfer
  """
  @spec changeset(Transfer.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Transfer{} = trans, attrs) do
    trans
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> put_assoc(:from, attrs.from)
    |> put_assoc(:to, attrs.to)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:from_id)
    |> foreign_key_constraint(:to_id)
    |> foreign_key_constraint(:community_id)
  end
end
