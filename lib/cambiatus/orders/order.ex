defmodule Cambiatus.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Orders.Item
  alias Cambiatus.Orders

  schema "orders" do
    field(:payment_method, Ecto.Enum,
      values: [:paypal, :bitcoin, :ethereum, :eos],
      default: :paypal
    )

    field(:total, :float)
    field(:status, :string)

    belongs_to(:buyer, User, references: :account, type: :string)

    has_many(:items, Item, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(payment_method total status)a
  @optional_fields ~w(inserted_at updated_at buyer_id)a

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_checkout()
  end

  def validate_checkout(changeset) do
    with order_id <- get_field(changeset, :id),
         {:ok, order} <- Orders.get_order(order_id) do
      if Map.get(order, :status) == "cart" and get_field(changeset, :status) == "checkout" do
      end
    end
  end
end
