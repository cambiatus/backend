defmodule Cambiatus.Shop do
  @moduledoc """
  Shop context, handles products, orders
  """

  import Ecto.Query

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

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs, :create)
    |> Repo.insert()
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

    query =
      if Map.has_key?(filters, :account) do
        Product.created_by(query, Map.get(filters, :account))
      else
        query
      end

    query =
      if Map.has_key?(filters, :in_stock) do
        Product.in_stock(query, Map.get(filters, :in_stock))
      else
        query
      end

    Repo.all(query)
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

  def get_order(id) do
    Repo.get(Order, id)
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
  def get_category(id), do: Repo.get(Category, id)

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
  def create_category(attrs \\ %{}) do
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
    with %Category{} = category <- get_category(category_id),
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
end
