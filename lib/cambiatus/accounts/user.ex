defmodule Cambiatus.Accounts.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.{Auth.Invitation, Notifications.PushSubscription, Repo}
  alias Cambiatus.Accounts.{Contact, User}
  alias Cambiatus.Commune.{Network, Transfer}
  alias Cambiatus.Kyc.{KycData, Address}
  alias Cambiatus.Shop.Product
  alias Cambiatus.Payments.Contribution
  alias Cambiatus.Objectives.Claim

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

    field(:language, Ecto.Enum,
      values: [:"en-US", :"pt-BR", :"es-ES", :"amh-ETH"],
      default: :"en-US"
    )

    field(:transfer_notification, :boolean, default: false)
    field(:claim_notification, :boolean, default: false)
    field(:digest, :boolean, default: false)

    field(:latest_accepted_terms, :naive_datetime)

    has_many(:push_subscriptions, PushSubscription, foreign_key: :account_id)
    has_many(:products, Product, foreign_key: :creator_id)
    has_many(:orders, through: [:products, :orders])
    has_many(:to_transfers, Transfer, foreign_key: :to_id)
    has_many(:from_transfers, Transfer, foreign_key: :from_id)
    has_many(:network, Network, foreign_key: :account_id)
    has_many(:roles, through: [:network, :network_roles, :role])
    has_many(:communities, through: [:network, :community])
    has_many(:invitations, Invitation, foreign_key: :creator_id)
    has_many(:claims, Claim, foreign_key: :claimer_id)
    has_many(:contributions, Contribution, foreign_key: :user_id)

    has_many(:contacts, Contact,
      foreign_key: :user_id,
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_one(:address, Address, foreign_key: :account_id)
    has_one(:kyc, KycData, foreign_key: :account_id)
  end

  @required_fields ~w(account email name)a

  @optional_fields ~w(bio location interests avatar created_block created_tx created_at created_eos_account
                      language transfer_notification claim_notification digest latest_accepted_terms)a

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
      put_assoc(changeset, :contacts, Map.get(attrs, :contacts))
    else
      changeset
    end
  end

  def search(query \\ User, filters) do
    Enum.reduce(filters, query, fn
      {:search_string, s}, query ->
        query
        |> where([u], fragment("?.name @@ plainto_tsquery(?)", u, ^s))
        |> or_where([u], fragment("?.account @@ plainto_tsquery(?)", u, ^s))
        |> or_where([u], fragment("?.bio @@ plainto_tsquery(?)", u, ^s))
        |> or_where([u], fragment("?.email @@ plainto_tsquery(?)", u, ^s))
        |> or_where([u], ilike(u.name, ^"%#{s}%"))
        |> or_where([u], ilike(u.account, ^"%#{s}%"))
        |> or_where([u], ilike(u.bio, ^"%#{s}%"))
        |> or_where([u], ilike(u.email, ^"%#{s}%"))

      {:ordering, o}, query ->
        query
        |> order_by([u], ^o)
    end)
  end

  def accept_digest(query \\ __MODULE__) do
    where(query, [u], u.digest == true)
  end
end
