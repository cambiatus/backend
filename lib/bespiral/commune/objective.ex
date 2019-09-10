defmodule BeSpiral.Commune.Objective do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias BeSpiral.Accounts.User
  alias BeSpiral.Commune.Action
  alias BeSpiral.Commune.Community

  schema "objectives" do
    field(:description, :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:creator, User, references: :account, type: :string)

    has_many(:actions, Action, foreign_key: :objective_id)
  end

  @required_fields ~w(community_id creator_id description)a
  @optional_fields ~w(created_block created_tx created_at created_eos_account)a

  @doc false
  def changeset(objective, attrs) do
    objective
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:creator_id)
  end
end
