defmodule Cambiatus.Objectives.Action do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.{Accounts.User}
  alias Cambiatus.Objectives.{Claim, Objective, Validator, Action, Reward}

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
    field(:has_proof_photo, :boolean, default: false)
    field(:has_proof_code, :boolean, default: false)
    field(:photo_proof_instructions, :string)

    field(:position, :integer)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:creator, User, references: :account, type: :string)
    belongs_to(:objective, Objective, references: :id, type: :integer)
    has_many(:vals, Validator)
    has_many(:validators, through: [:vals, :validator])
    has_many(:claims, Claim)
    has_many(:rewards, Reward)
  end

  @required_fields ~w(creator_id objective_id reward description verification_type)a
  @optional_fields ~w(deadline usages usages_left verifier_reward verifications is_completed
                       has_proof_photo has_proof_code photo_proof_instructions
                       created_block created_tx created_at created_eos_account)a

  @doc false
  def changeset(action, attrs) do
    action
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:verification_type, ["claimable", "automatic"])
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:objective_id)
  end

  def created_by(query \\ Action, account) do
    query
    |> where([a], a.creator_id == ^account)
  end

  def with_validator(query \\ Action, validator) do
    query
    |> join(:inner, [a], v in Validator, on: a.id == v.action_id and v.validator_id == ^validator)
  end

  def completed(query \\ Action, is_completed?) do
    query
    |> where([a], a.is_completed == ^is_completed?)
  end

  def available(query \\ Action) do
    {:ok, now} = DateTime.now("Etc/UTC")

    query
    |> join(:inner, [a], obj in Objective, on: obj.id == a.objective_id)
    |> completed(false)
    |> where([a], a.verification_type == "claimable")
    |> where([a], is_nil(a.deadline) or a.deadline >= ^now)
    |> where([a], (a.usages_left > 1 and a.usages > 0) or a.usages == 0)
    |> where([a, obj], obj.is_completed == false)
  end

  def with_verification_type_of(query \\ Action, verification_type) do
    query
    |> where([a], a.verification_type == ^verification_type)
  end

  def ordered(query \\ Action) do
    query
    |> order_by([a], a.position)
  end

  def search(query \\ Action, q) do
    query
    |> where([a], fragment("?.description @@ plainto_tsquery(?) ", a, ^q))
    |> or_where([a], ilike(a.description, ^"%#{q}%"))
  end
end
