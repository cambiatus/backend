defmodule Cambiatus.Commune.Transfer do
  @moduledoc """
  This module holds the data structure for transfers made in the commune context
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  @type t :: %__MODULE__{}

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.{Community, Transfer}

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
  def changeset(%Transfer{} = transfer, attrs) do
    transfer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> put_assoc(:from, attrs.from)
    |> put_assoc(:to, attrs.to)
    |> put_assoc(:community, attrs.community)
    |> foreign_key_constraint(:from_id)
    |> foreign_key_constraint(:to_id)
    |> foreign_key_constraint(:community_id)
  end

  def on_community(query \\ Transfer, community_id) do
    where(query, [t], t.community_id == ^community_id)
  end

  @doc """
  Transfer that the given `user` participates, both as a sender or a receiver
  """
  def with_user(query \\ Transfer, account) do
    where(query, [t], t.from_id == ^account or t.to_id == ^account)
  end

  def received_by(query \\ Transfer, account) do
    where(query, [t], t.to_id == ^account)
  end

  def sent_by(query \\ Transfer, account) do
    where(query, [t], t.from_id == ^account)
  end

  def newer_first(query \\ Transfer) do
    order_by(query, [t], desc: t.created_at)
  end

  def on_day(query \\ Transfer, date) do
    datetime = to_datetime(date)
    # add a day
    datetime_a_day_after = date |> Date.add(1) |> to_datetime()

    query
    |> where([t], t.created_at >= ^datetime)
    |> where([t], t.created_at < ^datetime_a_day_after)
  end

  def count(query \\ Transfer), do: select(query, [t], count(t.id))

  defp to_datetime(date) do
    {:ok, datetime, _} =
      date
      |> Date.to_iso8601()
      |> Kernel.<>("T00:00:00Z")
      |> DateTime.from_iso8601()

    datetime
  end
end
