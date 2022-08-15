defmodule Cambiatus.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Repo

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
    |> validate_checkout(order)
  end

  # TODO: Validate other fields(shipping, payment, total)
  def validate_checkout(changeset, order) do
    if Map.get(order, :status) == "cart" and get_field(changeset, :status) == "checkout" do
      changeset
      |> order_has_items(order)
      |> validate_items(order)
    else
      changeset
    end
  end

  def order_has_items(changeset, order) do
    if Orders.has_items?(order) do
      changeset
    else
      add_error(changeset, :items, "Orders has no items")
    end
  end

  def validate_items(changeset, order) do
    order
    |> Repo.preload(:items)
    |> Map.get(:items)
    |> Enum.reduce(changeset, fn item, changeset ->
      case Item.validate_item(%Ecto.Changeset{errors: []}, item) do
        %{errors: []} ->
          changeset

        error ->
          add_error(
            changeset,
            :items,
            "Item with id #{item.id} is invalid",
            reason: error.errors
          )
      end
    end)
  end
end
