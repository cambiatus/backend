defmodule Cambiatus.Shop.ProductCategory do
  @moduledoc """
  Intermediary table that relates Products and Categories, with an extra position field for ordering
  """

  use Ecto.Schema

  alias Cambiatus.Shop.{Category, Product}

  schema "product_categories" do
    field(:position, :integer)

    belongs_to(:product, Product)
    belongs_to(:category, Category)

    timestamps()
  end
end
