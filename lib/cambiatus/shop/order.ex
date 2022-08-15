defmodule Cambiatus.Shop.Order do
  @moduledoc """
  This module represents an Order.
  """

  use Ecto.Schema

  alias Cambiatus.Accounts.User

  schema "orders" do
    field(:payment_method, :string)
    field(:total, :float)
    field(:status, :string)

    field(:updated_at, :utc_datetime)
    field(:created_at, :utc_datetime)

    belongs_to(:buyer_id, User, references: :account, type: :string)
  end
end
