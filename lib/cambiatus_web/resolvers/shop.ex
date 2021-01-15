defmodule CambiatusWeb.Resolvers.Shop do
  @moduledoc """
  Resolver module for Shop operations, responsible to parse GraphQL params and adjust responses to it
  """

  alias Cambiatus.Shop

  def get_products(_, %{community_id: community_id, filters: filters}, _) do
    case Shop.list_products(community_id, filters) do
      results -> {:ok, results}
    end
  end

  def get_products(_, %{community_id: community_id}, _) do
    case Shop.list_products(community_id) do
      results -> {:ok, results}
    end
  end

  def get_product(_, %{id: id}, _) do
    case Shop.get_product(id) do
      nil ->
        {:error, "No product found with given ID"}

      product ->
        {:ok, product}
    end
  end
end
