defmodule Cambiatus.Orders.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Shop.Product
  alias Cambiatus.Orders.Order
  alias Cambiatus.Orders
  alias Cambiatus.Repo

  schema "items" do
    field(:units, :integer)
    field(:unit_price, :float)
    field(:status, :string)
    field(:shipping, :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)

    belongs_to(:product, Product)
    belongs_to(:order, Order)

    timestamps()
  end

  @required_fields ~w(units unit_price status)a
  @optional_fields ~w(shipping inserted_at updated_at product_id order_id)a

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  @spec changeset(Changeset.t(), Item.t()) :: Ecto.Changeset.t()
  def validate_item(changeset, item \\ %{}) do
    item = item || Orders.get_item!(fetch_change!(changeset, :id))

    changeset
    |> validate_item_stock(item)
  end

  def validate_item_stock(changeset, item) do
    with item <- Repo.preload(item, :product),
         product <- Map.get(item, :product) do
      case {product.track_stock, product.units >= item.units} do
        {true, true} ->
          changeset

        {true, false} ->
          add_error(changeset, :units, "Not enough product in stock")

        {false, _} ->
          changeset
      end
    end
  end
end
