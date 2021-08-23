defmodule Cambiatus.Payments.Contribution do
  @moduledoc """
  Ecto model for community contributions

  Contributions can happen via multiple payment methods and in many currencies
  """

  @type t :: %__MODULE__{}

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  alias Cambiatus.Commune.Community
  alias Cambiatus.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "contributions" do
    field(:amount, :float)

    field(:currency, Ecto.Enum, values: [:usd, :brl, :crc, :btc, :eth, :eos])
    field(:payment_method, Ecto.Enum, values: [:paypal, :bitcoin, :ethereum, :eos])
    field(:status, Ecto.Enum, values: [:created, :captured, :approved, :rejected, :failed])

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:account, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(community_id account_id amount currency payment_method status)a
  @optional_fields ~w()a

  def changeset(%__MODULE__{} = contribution, params) do
    contribution
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def from_community(query \\ __MODULE__, community_id) do
    where(query, [c], c.community_id == ^community_id)
  end

  def from_user(query \\ __MODULE__, account) do
    where(query, [c], c.account_id == ^account)
  end
end
