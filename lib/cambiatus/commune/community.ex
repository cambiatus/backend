defmodule Cambiatus.Commune.Community do
  @moduledoc false

  alias Cambiatus.{
    Commune.Community,
    Commune.Network,
    Commune.Mint,
    Commune.Objective,
    Shop.Product,
    Commune.Transfer
  }

  use Ecto.Schema
  import Ecto.Changeset

  @reserved_subdomain ~w(dev demo staging)
  @primary_key {:symbol, :string, autogenerate: false}
  schema "communities" do
    field(:creator, :string)
    field(:logo, :string)
    field(:name, :string)
    field(:description, :string)
    field(:subdomain, :string)
    field(:inviter_reward, :float)
    field(:invited_reward, :float)

    # Token configurations
    field(:type, :string)
    field(:supply, :float)
    field(:max_supply, :float)
    field(:min_balance, :float)
    field(:issuer, :string)
    field(:precision, :integer)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    # Features
    field(:has_objectives, :boolean, default: true)
    field(:has_shop, :boolean, default: true)
    field(:has_kyc, :boolean, default: false)

    has_many(:products, Product, foreign_key: :community_id)
    has_many(:transfers, Transfer, foreign_key: :community_id)
    has_many(:network, Network, foreign_key: :community_id)
    has_many(:members, through: [:network, :account])
    has_many(:objectives, Objective, foreign_key: :community_id)
    has_many(:actions, through: [:objectives, :actions])
    has_many(:mints, Mint, foreign_key: :community_id)
  end

  @required_fields ~w(symbol creator name description inviter_reward invited_reward)a
  @optional_fields ~w(logo type supply max_supply min_balance issuer precision created_block
  created_tx created_at created_eos_account subdomain)a

  @doc false
  def changeset(%Community{} = community, attrs) do
    community
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:subdomain)
    |> validate_exclusion(:subdomain, @reserved_subdomain)
  end
end
