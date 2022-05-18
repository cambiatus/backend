defmodule Cambiatus.ShopTest do
  use Cambiatus.DataCase

  describe "create_category/1" do
    test "create a valid category" do
      community = insert(:community, has_shop: true)
    end

    test "cannot crete categories with shop disabled"
  end
end
