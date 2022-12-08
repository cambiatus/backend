defmodule Cambiatus.Commune.Community do
  @moduledoc false

  alias Cambiatus.Accounts.Contact

  alias Cambiatus.Commune.{
    Community,
    CommunityPhotos,
    Mint,
    Network,
    Subdomain,
    Transfer
  }

  alias Cambiatus.Payments.{Contribution, ContributionConfiguration}
  alias Cambiatus.Repo
  alias Cambiatus.Shop.{Category, Product}
  alias Cambiatus.Social.News
  alias Cambiatus.Objectives.Objective

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:symbol, :string, autogenerate: false}
  schema "communities" do
    field(:creator, :string)
    field(:logo, :string)
    field(:name, :string)
    field(:description, :string)

    # Token configurations
    field(:type, :string)
    field(:supply, :float)
    field(:max_supply, :float)
    field(:min_balance, :float)
    field(:issuer, :string)

    # Configurations
    field(:inviter_reward, :float)
    field(:invited_reward, :float)
    field(:website, :string)
    field(:auto_invite, :boolean, default: false)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    # Features
    field(:has_objectives, :boolean, default: true)
    field(:has_shop, :boolean, default: true)
    field(:has_kyc, :boolean, default: false)

    # Social
    field(:has_news, :boolean, default: false)

    belongs_to(:highlighted_news, News)

    belongs_to(:subdomain, Subdomain)
    belongs_to(:contribution_configuration, ContributionConfiguration)

    has_many(:products, Product, foreign_key: :community_id)
    has_many(:orders, through: [:products, :orders])
    has_many(:news, News, foreign_key: :community_id)
    has_many(:transfers, Transfer, foreign_key: :community_id)
    has_many(:network, Network, foreign_key: :community_id)
    has_many(:members, through: [:network, :user])
    has_many(:objectives, Objective, foreign_key: :community_id)
    has_many(:actions, through: [:objectives, :actions])
    has_many(:mints, Mint, foreign_key: :community_id)
    has_many(:uploads, CommunityPhotos, foreign_key: :community_id, on_replace: :delete)
    has_many(:contributions, Contribution, foreign_key: :community_id)
    has_many(:rewards, through: [:objectives, :actions, :rewards])
    has_many(:roles, Cambiatus.Commune.Role, foreign_key: :community_id)

    has_many(:contacts, Contact,
      foreign_key: :community_id,
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:categories, Category, foreign_key: :community_id)
  end

  @required_fields ~w(symbol creator name inviter_reward invited_reward has_news)a
  @optional_fields ~w(description logo type supply max_supply min_balance issuer subdomain_id website
   created_block created_tx created_at created_eos_account highlighted_news_id)a

  @doc false
  def changeset(%Community{} = community, attrs) do
    community
    |> Repo.preload(:contacts)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:subdomain, with: &Subdomain.changeset/2)
    |> cast_assoc(:contribution_configuration, with: &ContributionConfiguration.changeset/2)
    |> validate_required(@required_fields)
    |> assoc_contacts(attrs)
  end

  def assoc_contacts(changeset, attrs) do
    if Map.has_key?(attrs, :contacts) do
      put_assoc(changeset, :contacts, Map.get(attrs, :contacts))
    else
      changeset
    end
  end

  def save_photos(%Community{} = community, urls) do
    uploads = Enum.map(urls, &%CommunityPhotos{url: &1})

    community
    |> Repo.preload([:uploads, :subdomain])
    |> changeset(%{})
    |> Ecto.Changeset.put_assoc(:uploads, uploads)
    |> Repo.update()
  end

  def by_subdomain(query \\ Community, subdomain) do
    query
    |> join(:left, [c], s in assoc(c, :subdomain))
    |> where([c, s], s.name == ^subdomain)
  end

  def with_news_enabled(query \\ Community) do
    where(query, [c], c.has_news == true)
  end
end
