defmodule CambiatusWeb.Resolvers.Shop do
  @moduledoc """
  Resolver module for Shop operations, responsible to parse GraphQL params and adjust responses to it
  """

  alias Cambiatus.Shop

  def upsert_product(_, %{id: product_id} = params, %{context: %{current_user: current_user}}) do
    params = Map.merge(params, %{creator_id: current_user.account})

    with product <- Shop.get_product(product_id),
         {:ok, updated_product} <- Shop.update_product(product, params) do
      {:ok, updated_product}
    else
      nil ->
        {:error, "Product not found", details: nil}

      {:error, error} ->
        Sentry.capture_message("Product update failed", extra: %{error: error})
        {:error, message: "Product update failed", details: Cambiatus.Error.from(error)}
    end
  end

  def upsert_product(_, params, %{context: %{current_user: current_user}}) do
    params
    |> Map.merge(%{creator_id: current_user.account})
    |> Shop.create_product()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("Product update failed", extra: %{error: reason})
        {:error, message: "Product update failed", details: Cambiatus.Error.from(reason)}

      {:ok, product} = result ->
        result
    end
  end

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
