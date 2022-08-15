defmodule Cambiatus.Shop do
  @moduledoc """
  Shop context, handles products, orders
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Cambiatus.Commune
  alias Cambiatus.Repo
  alias Cambiatus.Shop.{Category, Product, Order}

  @spec data(any) :: Dataloader.Ecto.t()
  def data(params \\ %{}) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def query(Product, %{query: query}) do
    Product
    |> Product.search(query)
    |> Product.active()
  end

  def query(Category, _) do
    Category
    |> Category.positional()
  end

  def query(queryable, _params) do
    queryable
  end

  def validate_community_shop_enabled(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  def validate_community_shop_enabled(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.get_field(:community_id)
    |> Commune.get_community()
    |> case do
      {:ok, community} ->
        if Map.get(community, :has_shop),
          do: changeset,
          else: Ecto.Changeset.add_error(changeset, :community_id, "shop is not enabled")

      {:error, _} ->
        Ecto.Changeset.add_error(changeset, :community_id, "does not exist")
    end
  end

  def create_product(%{categories: categories} = attrs) do
    attrs =
      attrs
      |> Map.merge(%{product_categories: Enum.map(categories, &%{category_id: &1})})
      |> Map.delete(:categories)

    create_product(attrs)
  end

  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs, :create)
    |> Repo.insert()
  end

  def update_product(%Product{} = product, %{categories: categories} = attrs)
      when is_list(categories) do
    attrs =
      attrs
      |> Map.merge(%{product_categories: Enum.map(categories, &%{category_id: &1})})
      |> Map.delete(:categories)

    update_product(product, attrs)
  end

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs, :update)
    |> Repo.update()
  end

  def list_products(community_id, filters \\ %{}) do
    query =
      Product
      |> Product.from_community(community_id)
      |> Product.active()
      |> Product.newer_first()

    filters
    |> Enum.reduce(query, fn
      {:account, account}, query ->
        query
        |> Product.created_by(account)

      {:in_stock, in_stock}, query ->
        query
        |> Product.in_stock(in_stock)

      {:categories_ids, categories_ids}, query ->
        query
        |> Product.in_categories(categories_ids)
    end)
    |> Repo.all()
  end

  def get_product(id) do
    case Repo.get(Product, id) do
      nil ->
        nil

      product ->
        # Handle soft delete as nil
        if product.is_deleted do
          nil
        else
          product
        end
    end
  end

  def delete_product(product_id, current_user) do
    with %Product{} = product <- get_product(product_id),
         product <- Repo.preload(product, [:community, :creator]),
         true <-
           Commune.is_community_admin?(product.community.symbol, current_user) ||
             product.creator_id ==
               current_user.account do
      product
      |> Product.changeset(%{}, :delete)
      |> Repo.update()
    else
      nil ->
        {:error, "Product not found"}

      false ->
        {:error, " Logged user can't do this action"}
    end
  end

  def community_product_count(community_id) do
    query =
      from(p in Product,
        where: p.community_id == ^community_id,
        select: count(p.id)
      )

    query
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      results -> {:ok, results}
    end
  end

  def community_order_count(community_id) do
    query =
      from(o in Order,
        join: p in Product,
        where: p.community_id == ^community_id,
        where: p.id == o.product_id,
        select: count(o.id)
      )

    query
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      results -> {:ok, results}
    end
  end

  def count_categories(nil), do: {:error, "Community id cannot be `nil`"}

  def count_categories(community_id) do
    Category
    |> Category.from_community(community_id)
    |> Category.roots()
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category. Returns nil if not found

  ## Examples

      iex> get_category(123)
      %Category{}

      iex> get_category(0)
      nil

  """
  def get_category(id) do
    case Repo.get(Category, id) do
      nil ->
        {:error, "No category exists with the id: #{id}"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(%{categories: _} = attrs) do
    attrs
    |> Map.delete(:categories)
    |> create_category()
    |> case do
      {:ok, category} ->
        update_category(category, attrs)

      {:error, _} = error ->
        error
    end
  end

  def create_category(%{position: position} = attrs) do
    # Only try to automatically reorder if its a root category

    case Map.get(attrs, :parent_id) do
      nil ->
        transaction =
          Multi.new()
          |> Multi.insert(:category, Category.changeset(%Category{}, attrs))

        # Get all root categories that have position bigger or equal than
        transaction =
          Category
          |> Category.roots()
          |> Category.position_bigger_equals_then(position)
          |> Repo.all()
          |> Enum.reduce(transaction, fn cat, multi ->
            Multi.update(
              multi,
              {:category, cat.id},
              Category.changeset(cat, %{position: cat.position + 1})
            )
          end)

        transaction
        |> Repo.transaction()
        |> case do
          {:ok, %{category: new_category}} ->
            {:ok, new_category}

          {:error, :category, error, _} ->
            {:error, error}

          _error ->
            {:error, "Can't create new category"}
        end

      _ ->
        %Category{}
        |> Category.changeset(attrs)
        |> Repo.insert()
    end
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, %{categories: categories} = attrs) do
    # Happens only on subcategories
    transaction =
      Multi.new()
      |> Multi.update(:category, Category.changeset(category, Map.delete(attrs, :categories)))

    categories
    |> Enum.reduce(transaction, fn sub_category_attrs, multi ->
      changeset =
        Category
        |> Repo.get(sub_category_attrs.id)
        |> Category.changeset(Map.merge(sub_category_attrs, %{parent_id: category.id}))

      Multi.update(multi, {:sub_category, sub_category_attrs.id}, changeset)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{category: category}} ->
        {:ok, category}

      _ ->
        {:error, "Cannot update category"}
    end
  end

  def update_category(
        %Category{} = %{parent_id: parent_id, position: old_position} = category,
        %{position: new_position} = attrs
      )
      when is_nil(parent_id) do
    # Do category position change first
    transaction =
      Multi.new()
      |> Multi.update(:category, Category.changeset(category, attrs))

    # Change all elements between the old position and the new position
    Category
    |> Category.between_positions(old_position, new_position)
    |> Repo.all()
    |> Enum.reduce(transaction, fn cat, multi ->
      # 1. The new position is  > old position: Decrease position
      # 2. The new position is < old position: Increase position
      Multi.update(
        multi,
        {:category, cat.id},
        Category.changeset(cat, %{
          position: if(new_position > old_position, do: cat.position - 1, else: cat.position + 1)
        })
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{category: updated_category}} ->
        {:ok, updated_category}

      {:error, :category, error, _} ->
        {:error, error}

      _error ->
        {:error, "Cannot update category"}
    end
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category_id)
      {:ok, %Category{}}

      iex> delete_category(category_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(category_id, user, community_id) do
    with %Category{} = category <- get_category!(category_id),
         true <- category.community_id == community_id,
         true <- Commune.is_community_admin?(category.community_id, user.account) do
      case Repo.delete(category) do
        {:ok, _} -> {:ok, "Category deleted successfully"}
        _ -> {:error, "Category delete failed"}
      end
    else
      nil ->
        {:error, "Category not found"}

      false ->
        {:error, "Logged user can't do this action"}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Cambiatus.Shop.Order

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
  Deletes an order.

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

  def has_items?(%Order{} = order) do
    order
    |> Repo.preload(:items)
    |> Map.get(:items)
    |> Enum.any?()
  end

  alias Cambiatus.Shop.Item

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
  Creates an item.

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
