defmodule Cambiatus.Commune.Validator do
  @moduledoc """
  Datatstructure for an action validator in `Cambiatus`
  """

  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias Cambiatus.{
    Accounts.User,
    Commune.Validator,
    Commune.Action
  }

  @primary_key false
  schema "validators" do
    belongs_to(:action, Action, primary_key: true)
    belongs_to(:validator, User, primary_key: true, references: :account, type: :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end

  @required_fields ~w(action_id validator_id created_block created_tx created_eos_account created_at)a

  @spec changeset(Validator.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Validator{} = validator, attrs) do
    validator
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %Validator{}
    |> changeset(attrs)
    |> foreign_key_constraint(:action_id)
    |> foreign_key_constraint(:validator_id)
  end
end
