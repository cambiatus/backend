defmodule Cambiatus.Shop.ProductCategory do
  @moduledoc """
  Intermediary table that relates Products and Categories, with an extra position field for ordering
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Shop.{Category, Product}

  schema "product_categories" do
    field(:position, :integer)

    belongs_to(:product, Product)
    belongs_to(:category, Category)

    timestamps()
  end

  @required_params ~w(product_id category_id)a
  @optional_params ~w(position)a

  def changeset(product_category, params \\ %{}) do
    product_category
    |> cast(params, @required_params ++ @optional_params)
    |> unique_constraint([:product_id, :category_id])
    |> unique_constraint([:category_id, :product_id])
  end
end
