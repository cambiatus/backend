defmodule Cambiatus.Commune.Claim do
  @moduledoc """
  Datastructure for a claim in `Cambiatus`
  """

  @type t :: %__MODULE__{}
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.{
    Accounts.User,
    Commune.Action,
    Commune.Claim,
    Commune.Check
  }

  schema "claims" do
    field(:is_verified, :boolean)
    field(:status, :string)
    belongs_to(:action, Action)
    belongs_to(:claimer, User, references: :account, type: :string)
    has_many(:checks, Check)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end

  @required_fields ~w(is_verified action_id claimer_id created_block created_tx created_eos_account created_at)a

  @spec changeset(Claim.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Claim{} = claim, attrs) do
    claim
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %Claim{}
    |> changeset(attrs)
    |> foreign_key_constraint(:action_id)
    |> foreign_key_constraint(:claimer_id)
  end
end
