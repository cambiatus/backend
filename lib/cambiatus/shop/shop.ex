defmodule Cambiatus.Shop do
  @moduledoc """
  Shop context, handles products, orders
  """

  import Ecto.Query

  alias Cambiatus.Repo
  alias Cambiatus.Shop.{Product, Order}

  @spec data(any) :: Dataloader.Ecto.t()
  def data(params \\ %{}) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def query(queryable, _params) do
    queryable
  end

  @spec list_products(binary) :: list(Product.t())
  def list_products(community_id) do
    Product
    |> Product.from_community(community_id)
    |> Product.active()
    |> Repo.all()
  end

  def list_products(community_id, account) do
    Product
    |> Product.from_community(community_id)
    |> Product.created_by(account)
    |> Repo.all()
  end

  def get_product(id) do
    Repo.get(Product, id)
  end

  def community_product_count(community_id) do
    from(p in Product,
      where: p.community_id == ^community_id,
      select: count(p.id)
    )
    |> Repo.one()
    |> case do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  def get_order(id) do
    Repo.get(Order, id)
  end
end
