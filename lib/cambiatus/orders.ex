defmodule Cambiatus.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias Cambiatus.Repo

  alias Cambiatus.Orders.Order
  alias Cambiatus.Shop.Product

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Gets a single order.

  Returns {:error, "No order exists with the id: {id}} if the Order does not exist.

  ## Examples

      iex> get_order(123)
      {:ok, %Order{}}

      iex> get_order(456)
      {:error, "Could not find order with id: {id}}

  """
  def get_order(id) do
    case Repo.get(Order, id) do
      nil ->
        {:error, "No order exists with the id: #{id}"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

  iex> get_order!(123)
  %Order{}

  iex> get_order!(456)
  ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Gets a single order.

  Returns {:error, "No order exists with the id: {id}} if the Order does not exist.

  ## Examples

      iex> get_order(123)
      {:ok, %Order{}}

      iex> get_order(456)
      {:error, "Could not find order with id: {id}}

  """

  # TODO: Add current_user to query
  def get_shopping_cart(buyer) do
    Order
    |> where([o], o.status == "cart")
    |> join(:left, [o], b in assoc(o, :buyer))
    |> where([o, b], b.account == ^buyer.account)
    |> Repo.all()
    |> case do
      [] ->
        {:error, "User has no shopping cart"}

      [value] ->
        {:ok, value}

      _ ->
        {:error, "User has more than one shopping cart"}
    end
  end

  @doc """
  Creates an order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an order.

  ## Examples

      iex> create_order!(%{field: value})
      %Order{}

      iex> create_order!(%{field: bad_value})
      Error

  """
  def create_order!(attrs \\ %{status: "cart", payment_method: "eos", total: 0}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates an order.
  
  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  alias Cambiatus.Orders.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Returns {:error, "No item exists with the id: {id}} if the Item does not exist.

  ## Examples

      iex> get_item(123)
      {:ok, %Item{}}

      iex> get_item(456)
      {:error, "Could not find item with id: {id}}

  """
  def get_item(id) do
    case Repo.get(Item, id) do
      nil ->
        {:error, "No item exists with the id: #{id}"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{})

  def create_item(%{order_id: _id} = attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  def create_item(%{buyer: buyer} = attrs) do
    case get_shopping_cart(buyer) do
      {:error, "User has no shopping cart"} ->
        cart = create_order!()

        attrs
        |> Map.put(:order_id, cart.id)
        |> create_item()

      {:ok, order} ->
        attrs
        |> Map.put(:order_id, order.id)
        |> create_item()

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates an item.
  
  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an item.
  
  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end
end
