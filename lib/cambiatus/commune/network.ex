defmodule Cambiatus.Commune.Network do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community

  schema "network" do
    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:account, User, references: :account, type: :string)
    belongs_to(:invited_by, User, references: :account, type: :string)
  end

  @required_fields ~w(account_id community_id invited_by_id)a
  @optional_fields ~w(created_block created_tx created_at created_eos_account)a

  @doc false
  def changeset(network, attrs) do
    network
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:invited_by_id)
  end
end
