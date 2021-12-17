defmodule Cambiatus.Commune.Network do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.{Community, Network, NetworkRoles, Role}

  schema "network" do
    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:user, User, references: :account, type: :string, foreign_key: :account_id)
    belongs_to(:invited_by, User, references: :account, type: :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    many_to_many(:roles, Role, join_through: NetworkRoles)
  end

  @required_fields ~w(account_id community_id invited_by_id)a
  @optional_fields ~w(created_block created_tx created_at created_eos_account role_id)a

  @doc false
  def changeset(network, attrs) do
    network
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:invited_by_id)
  end

  def by_community(query \\ Network, community_id) do
    query
    |> where([n], n.community_id == ^community_id)
  end

  def by_user(query \\ Network, account) do
    query
    |> where([n], n.account_id == ^account)
  end
end
