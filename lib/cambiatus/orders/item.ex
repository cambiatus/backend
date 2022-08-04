defmodule Cambiatus.Orders.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Shop.Product
  alias Cambiatus.Accounts.User
  alias Cambiatus.Orders.Order

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
  @optional_fields ~w(shipping inserted_at updated_at)a

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
