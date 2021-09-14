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
  alias Cambiatus.Payments.{ContributionPaymentCallback, PaymentCallback}

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

    many_to_many(:payment_callbacks, PaymentCallback,
      join_through: ContributionPaymentCallback,
      unique: true,
      on_replace: :delete
    )

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

    if is_payment_method_valid?(currency, payment_method) do
      changeset
    else
      add_error(
        changeset,
        :payment_method,
        "Payment method #{payment_method} is invalid for currency #{currency}"
      )
    end
  end

  def is_payment_method_valid?(currency, payment_method)
  def is_payment_method_valid?(:USD, :paypal), do: true
  def is_payment_method_valid?(:BRL, :paypal), do: true
  def is_payment_method_valid?(:CRC, :paypal), do: true
  def is_payment_method_valid?(:BTC, :bitcoin), do: true
  def is_payment_method_valid?(:ETH, :ethereum), do: true
  def is_payment_method_valid?(:EOS, :eos), do: true
  def is_payment_method_valid?(_, _), do: false

  def from_community(query \\ __MODULE__, community_id) do
    where(query, [c], c.community_id == ^community_id)
  end

  def from_user(query \\ __MODULE__, account) do
    where(query, [c], c.account_id == ^account)
  end

  def approved(query \\ __MODULE__) do
    where(query, [c], c.status == :approved)
  end

  def newer_first(query \\ __MODULE__) do
    order_by(query, [c], desc: c.inserted_at)
  end
end
