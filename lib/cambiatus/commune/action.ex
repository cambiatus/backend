defmodule Cambiatus.Commune.Action do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.{
    Accounts.User,
    Commune.Claim,
    Commune.Objective,
    Commune.Validator
  }

  schema "actions" do
    field(:description, :string)
    field(:reward, :float)
    field(:verifier_reward, :float)
    field(:deadline, :utc_datetime)
    field(:usages, :integer)
    field(:usages_left, :integer)
    field(:verifications, :integer)
    field(:verification_type, :string)
    field(:is_completed, :boolean, default: false)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:objective, Objective, references: :id, type: :integer)
    has_many(:vals, Validator)
    has_many(:validators, through: [:vals, :validator])
    has_many(:claims, Claim)

    @required_fields ~w(creator_id objective_id reward description verification_type)a
    @optional_fields ~w(is_completed deadline usages usages_left verifier_reward verifications created_block created_tx created_at created_eos_account)a

    @doc false
    def changeset(action, attrs) do
      action
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_inclusion(:verification_type, ["claimable", "automatic"])
      |> foreign_key_constraint(:creator_id)
      |> foreign_key_constraint(:objective_id)
    end
  end
end
