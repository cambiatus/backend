defmodule Cambiatus.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Orders.Item

  schema "orders" do
    field(:payment_method, :string)
    field(:total, :float)
    field(:status, :string)

    belongs_to(:buyer, User, references: :account, type: :string)

    has_many(:items, Item, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(payment_method total status)a
  @optional_fields ~w(inserted_at updated_at)a

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
