defmodule Cambiatus.Shop do
  @moduledoc """
  Shop context, handles products, orders
  """

  import Ecto.Query

  alias Cambiatus.Commune
  alias Cambiatus.Repo
  alias Cambiatus.Shop.{Product, Order}

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
end
