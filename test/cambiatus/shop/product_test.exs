defmodule Cambiatus.Shop.ProductTest do
  use Cambiatus.DataCase

  alias Cambiatus.Shop
  alias Cambiatus.Shop.Product

  describe "changeset validations" do
    setup do
      community = insert(:community)

      params = %{
        community_id: community.symbol,
        title: "Test product",
        description: "Lorem ...",
        price: 7,
        images: [],
        track_stock: false
      }

      %{params: params}
    end

    test "changeset with units without track_stock", %{params: params} do
      changeset =
        Product.changeset(
          %Product{},
          Map.merge(params, %{track_stock: false, units: 10}),
          :update
        )

      assert %{units: ["cannot be filled if track_stock is false"]} == errors_on(changeset)
    end

    test "deletes product" do
      user = insert(:user)
      product = insert(:product, %{creator: user})
      user = Cambiatus.Accounts.get_user(product.creator_id)

      assert Shop.get_product(product.id)

      assert {:ok, _} = Shop.delete_product(product.id, user)

      refute Shop.get_product(product.id)
    end
  end
end
