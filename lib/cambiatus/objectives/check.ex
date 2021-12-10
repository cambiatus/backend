defmodule Cambiatus.Objectives.Check do
  @moduledoc """
  Datastructure to represent the action of verifying a claim
  """

  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias Cambiatus.Accounts.User
  alias Cambiatus.Objectives.{Check, Claim}

  @primary_key false
  schema "checks" do
    field(:is_verified, :boolean, default: false)
    belongs_to(:claim, Claim, primary_key: true)
    belongs_to(:validator, User, primary_key: true, references: :account, type: :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end

  @required_fields ~w(is_verified claim_id validator_id created_block created_tx created_eos_account created_at)a

  @spec changeset(Check.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Check{} = check, attrs) do
    check
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %Check{}
    |> changeset(attrs)
    |> foreign_key_constraint(:claim_id)
    |> foreign_key_constraint(:validator_id)
  end
end
