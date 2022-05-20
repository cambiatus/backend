defmodule CambiatusWeb.Resolvers.Shop do
  @moduledoc """
  Resolver module for Shop operations, responsible to parse GraphQL params and adjust responses to it
  """

  alias Cambiatus.Shop
  alias Cambiatus.Shop.{Category, Product}

  def upsert_product(_, %{id: product_id} = params, %{context: %{current_user: current_user}}) do
    params = Map.merge(params, %{creator_id: current_user.account})

    with %Product{} = product <- Shop.get_product(product_id),
         {:ok, updated_product} <- Shop.update_product(product, params) do
      {:ok, updated_product}
    else
      nil ->
        {:error, "Product not found"}

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
        Sentry.capture_message("Product creation failed", extra: %{error: reason})
        {:error, message: "Product creation failed", details: Cambiatus.Error.from(reason)}

      {:ok, _product} = result ->
        result
    end
  end

  def get_products(_, %{community_id: community_id, filters: filters}, _) do
    case Shop.list_products(community_id, filters) do
      results -> {:ok, results}
    end
  end

  def get_products(_, %{community_id: community_id}, _) do
    results = Shop.list_products(community_id)

    {:ok, results}
  end

  def get_product(_, %{id: id}, _) do
    case Shop.get_product(id) do
      nil ->
        {:error, "No product found with given ID"}

      product ->
        {:ok, product}
    end
  end

  def delete_product(_, %{id: product_id}, %{context: %{current_user: current_user}}) do
    case Shop.delete_product(product_id, current_user) do
      {:error, reason} ->
        Sentry.capture_message("Product deletion failed", extra: %{error: reason})

        {:ok, %{status: :error, reason: reason}}

      {:ok, message} ->
        {:ok, %{status: :success, reason: message}}
    end
  end

  def upsert_category(_, %{id: category_id} = params, %{
        context: %{current_community_id: community_id}
      }) do
    params = Map.merge(params, %{community_id: community_id})

    with %Category{} = category <- Shop.get_category(category_id),
         {:ok, updated_category} <- Shop.update_category(category, params) do
      {:ok, updated_category}
    else
      nil ->
        {:error, "Category not found"}

      {:error, error} ->
        Sentry.capture_message("Category update failed", extra: %{error: error})
        {:error, message: "Category update failed", details: Cambiatus.Error.from(error)}
    end
  end

  def upsert_category(_, params, %{context: %{current_community_id: community_id}}) do
    params = Map.merge(params, %{community_id: community_id})

    params
    |> Shop.create_category()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("Category creation failed", extra: %{error: reason})
        {:error, message: "Category creation failed", details: Cambiatus.Error.from(reason)}

      {:ok, _product} = result ->
        result
    end
  end
end
