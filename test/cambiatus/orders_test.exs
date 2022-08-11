defmodule Cambiatus.OrdersTest do
  use Cambiatus.DataCase

  alias Cambiatus.Orders

  describe "orders" do
    alias Cambiatus.Orders.Order

    @valid_attrs %{
      payment_method: "eos",
      total: 10.2,
      status: "cart"
    }
    @update_attrs %{
      payment_method: "paypal",
      total: 560,
      status: "pending payment"
    }
    @invalid_attrs %{
      payment_method: nil,
      total: nil,
      status: nil
    }

    def order_fixture(attrs \\ %{}) do
      {:ok, order} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Orders.create_order()

      order
    end

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates an order" do
      assert {:ok, %Order{} = order} = Orders.create_order(@valid_attrs)
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      assert {:ok, %Order{} = order} = Orders.update_order(order, @update_attrs)
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns an order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end

    test "deleting an order deletes all items associated to it" do
      order = insert(:order)
      item1 = insert(:item, %{order: order})
      item2 = insert(:item, %{order: order})
      item3 = insert(:item, %{order: order})

      order = Repo.preload(order, :items)

      assert Enum.count(order.items) == 3

      Orders.delete_order(order)

      assert Orders.get_order(order.id) == {:error, "No order exists with the id: #{order.id}"}
      assert Orders.get_item(item1.id) == {:error, "No item exists with the id: #{item1.id}"}
      assert Orders.get_item(item2.id) == {:error, "No item exists with the id: #{item2.id}"}
      assert Orders.get_item(item3.id) == {:error, "No item exists with the id: #{item3.id}"}
    end
  end

  describe "items" do
    alias Cambiatus.Orders.Item

    @valid_attrs %{
      units: 2,
      unit_price: 5.2,
      status: "pending"
    }
    @update_attrs %{
      units: 60,
      unit_price: 2,
      status: "in transport",
      shipping: "chariot"
    }
    @invalid_attrs %{
      units: nil,
      unit_price: nil,
      status: nil
    }

    def item_fixture(attrs \\ %{}) do
      {:ok, item} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Orders.create_item()

      item
    end

    setup do
      %{user: insert(:user)}
    end

    test "list_items/0 returns all items", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert Orders.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert Orders.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates an item", %{user: user} do
      assert {:ok, %Item{} = item} = Orders.create_item(Map.merge(@valid_attrs, %{buyer: user}))
    end

    test "create_item/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} =
               Orders.create_item(Map.merge(@invalid_attrs, %{buyer: user}))
    end

    test "update_item/2 with valid data updates the item", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert {:ok, %Item{} = item} = Orders.update_item(item, @update_attrs)
    end

    test "update_item/2 with invalid data returns error changeset", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert {:error, %Ecto.Changeset{}} = Orders.update_item(item, @invalid_attrs)
      assert item == Orders.get_item!(item.id)
    end

    test "delete_item/1 deletes the item", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert {:ok, %Item{}} = Orders.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_item!(item.id) end
    end

    test "change_item/1 returns an item changeset", %{user: user} do
      item = item_fixture(%{buyer: user})
      assert %Ecto.Changeset{} = Orders.change_item(item)
    end

    test "add item to existing cart", %{user: user} do
      cart = insert(:order, %{status: "cart", buyer: user})

      item =
        item_fixture(%{buyer: user})
        |> Repo.preload(:order)

      assert item.order.id == cart.id
    end
  end
end
