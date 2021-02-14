defmodule Cambiatus.Shop.Order do
  @moduledoc """
  This module represents an Order.
  """

  use Ecto.Schema

  alias Cambiatus.{Accounts.User, Shop.Product}

  schema "orders" do
    field(:amount, :float)
    field(:units, :integer)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)

    belongs_to(:product, Product)
    belongs_to(:from, User, references: :account, type: :string)
    belongs_to(:to, User, references: :account, type: :string)
  end
end
