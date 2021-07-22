defmodule Cambiatus.Commune.Claim do
  @moduledoc """
  Datastructure for a claim in `Cambiatus`
  """

  @type t :: %__MODULE__{}
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.Commune.{Action, Claim, Check, Objective}
  alias Cambiatus.Accounts.User

  schema "claims" do
    field(:status, :string)
    field(:proof_photo, :string)
    field(:proof_code, :string)

    belongs_to(:action, Action)
    belongs_to(:claimer, User, references: :account, type: :string)
    has_many(:checks, Check)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end

  @required_fields ~w(action_id status claimer_id created_block created_tx created_eos_account created_at)a
  @optional_fields ~w(proof_photo proof_code)a

  @spec changeset(Claim.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Claim{} = claim, attrs) do
    claim
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, ["approved", "rejected", "pending"])
  end

  def create_changeset(attrs) do
    %Claim{}
    |> changeset(attrs)
    |> foreign_key_constraint(:action_id)
    |> foreign_key_constraint(:claimer_id)
  end

  def by_community(query \\ Claim, community_id) do
    query
    |> join(:inner, [c], a in Action, on: a.id == c.action_id)
    |> join(:inner, [c, a], o in Objective, on: o.id == a.objective_id)
    |> where([c, a, o], o.community_id == ^community_id)
  end

  def newer_first(query \\ Claim) do
    query |> ordered(:desc)
  end

  def with_claimer(query \\ Claim, claimer) do
    query |> where(claimer_id: ^claimer)
  end

  def with_status(query \\ Claim, status) do
    query |> where(status: ^status)
  end

  def analyzed(query \\ Claim) do
    query
    |> where(status: "approved")
    |> or_where(status: "rejected")
  end

  def ordered(query \\ Claim, direction \\ :asc)
  def ordered(query, :asc), do: query |> order_by([a], a.created_at)
  def ordered(query, :desc), do: query |> order_by([a], desc: a.created_at)

  def count(query \\ Claim), do: select(query, [claim], count(claim.id))
end
