defmodule Cambiatus.Accounts.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.{Auth.Invitation, Notifications.PushSubscription, Repo}
  alias Cambiatus.Accounts.{Contact, User}
  alias Cambiatus.Commune.{Network, Claim, Transfer}
  alias Cambiatus.Kyc.{KycData, Address}
  alias Cambiatus.Shop.Product

  @primary_key {:account, :string, autogenerate: false}
  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:bio, :string)
    field(:location, :string)
    field(:interests, :string)
    field(:avatar, :string)

    field(:chat_user_id, :string, virtual: true)
    field(:chat_token, :string, virtual: true)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_at, :utc_datetime)
    field(:created_eos_account, :string)

    has_many(:push_subscriptions, PushSubscription, foreign_key: :account_id)
    has_many(:products, Product, foreign_key: :creator_id)
    has_many(:orders, through: [:products, :orders])
    has_many(:to_transfers, Transfer, foreign_key: :to_id)
    has_many(:from_transfers, Transfer, foreign_key: :from_id)
    has_many(:network, Network, foreign_key: :account_id)
    has_many(:communities, through: [:network, :community])
    has_many(:invitations, Invitation, foreign_key: :creator_id)
    has_many(:claims, Claim, foreign_key: :claimer_id)

    has_many(:contacts, Contact,
      foreign_key: :user_id,
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_one(:address, Address, foreign_key: :account_id)
    has_one(:kyc, KycData, foreign_key: :account_id)
  end

  @required_fields ~w(account email name)a
  @optional_fields ~w(bio location interests avatar created_block created_tx created_at created_eos_account)a

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> Repo.preload(:contacts)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:account)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:account, ~r/^[a-z1-5]{12}$/)
    |> assoc_contacts(attrs)
  end

  def assoc_contacts(changeset, attrs) do
    if Map.has_key?(attrs, :contacts) do
      changeset
      |> put_assoc(:contacts, Map.get(attrs, :contacts))
    else
      changeset
    end
  end
end
