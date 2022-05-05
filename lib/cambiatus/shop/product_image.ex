defmodule Cambiatus.Shop.ProductImage do
  @moduledoc """
  Ecto entity for product images
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Shop.{Product, ProductImage}

  schema "product_images" do
    field(:uri, :string)
    belongs_to(:product, Product)

    timestamps()
  end

  @required_fields ~w(uri product_id)a
  @optional_fields ~w()a

  def changeset(%ProductImage{} = image, attrs) do
    image
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
