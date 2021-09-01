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
  alias Cambiatus.Payments.ContributionPaymentCallback

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "contributions" do
    field(:amount, :float)

    field(:currency, Ecto.Enum, values: [:USD, :BRL, :CRC, :BTC, :ETH, :EOS], default: :USD)

    field(:payment_method, Ecto.Enum,
      values: [:paypal, :bitcoin, :ethereum, :eos],
      default: :paypal
    )

    field(:status, Ecto.Enum,
      values: [:created, :captured, :approved, :rejected, :failed],
      default: :created
    )

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:user, User, references: :account, type: :string)

    has_many(:contribution_payment_callbacks, ContributionPaymentCallback)
    has_many(:payment_callbacks, through: [:contribution_payment_callbacks, :payment_callback])

    timestamps()
  end

  @required_fields ~w(community_id user_id amount currency payment_method status)a
  @optional_fields ~w()a

  def changeset(%__MODULE__{} = contribution, params) do
    contribution
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_payment_method()
  end

  # If it is invalid at this point, don't keep validating
  def validate_payment_method(%{valid?: false} = changeset), do: changeset

  def validate_payment_method(%{valid?: true} = changeset) do
    currency = get_field(changeset, :currency)
    payment_method = get_field(changeset, :payment_method)

    unless validate_currency_payment_method(currency, payment_method) do
      add_error(
        changeset,
        :payment_method,
        "Payment method #{payment_method} is invalid for currency #{currency}"
      )
    else
      changeset
    end
  end

  def validate_currency_payment_method(currency, payment_method)
  def validate_currency_payment_method(:USD, :paypal), do: true
  def validate_currency_payment_method(:BRL, :paypal), do: true
  def validate_currency_payment_method(:CRC, :paypal), do: true
  def validate_currency_payment_method(:BTC, :bitcoin), do: true
  def validate_currency_payment_method(:ETH, :ethereum), do: true
  def validate_currency_payment_method(:EOS, :eos), do: true
  def validate_currency_payment_method(_, _), do: false

  def from_community(query \\ __MODULE__, community_id) do
    where(query, [c], c.community_id == ^community_id)
  end

  def from_user(query \\ __MODULE__, account) do
    where(query, [c], c.account_id == ^account)
  end
end
