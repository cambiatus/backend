defmodule CambiatusWeb.Resolvers.Social do
  @moduledoc """
  This module holds the implementation of the resolver for the Social context
  use this to resolve any queries and mutations for Social
  """

  alias Cambiatus.{Commune, Social}

  def news(_, params, %{context: %{current_user: current_user}}) do
    params
    |> Map.merge(%{user_id: current_user.account})
    |> Social.create_news()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("News creation failed", extra: %{error: reason})
        {:error, message: "Could not create news", details: Cambiatus.Error.from(reason)}

      {:ok, news} ->
        {:ok, news}
    end
  end

  def update_news(_, %{id: news_id} = params, _) do
    Social.get_news(news_id)
    |> do_update_news(params)
    |> case do
      {:ok, transaction_response} -> {:ok, transaction_response.news}
      {:error, error} -> handle_news_update_error(error)
      {:error, _, error, _} -> handle_news_update_error(error)
    end
  end

  defp do_update_news(nil, _), do: {:error, "News not found"}
  defp do_update_news(news, params), do: Social.update_news_with_history(news, params)

  defp handle_news_update_error(error) do
    Sentry.capture_message("News update failed", extra: %{error: error})
    {:error, message: "Could not update news", details: Cambiatus.Error.from(error)}
  end

  def mark_news_as_read(_, %{news_id: news_id}, %{context: %{current_user: current_user}}) do
    Social.upsert_news_receipt(news_id, current_user.account)
    |> case do
      {:error, reason} ->
        Sentry.capture_message("News Receipt upsert failed", extra: %{error: reason})
        {:error, message: "Could not upsert news receipt", details: Cambiatus.Error.from(reason)}

      {:ok, receipt} ->
        {:ok, receipt}
    end
  end

  def update_reactions(_, %{news_id: news_id, reactions: reactions}, %{
        context: %{current_user: current_user}
      }) do
    Social.upsert_news_receipt(news_id, current_user.account, reactions)
    |> case do
      {:error, reason} ->
        Sentry.capture_message("Failed to update reactions to news", extra: %{error: reason})

        {:error,
         message: "Could not update news reactions", details: Cambiatus.Error.from(reason)}

      {:ok, receipt} ->
        {:ok, receipt}
    end
  end

  def get_reactions(%{id: news_id}, _, _) do
    reactions = Social.get_news_reactions(news_id)

    {:ok, reactions}
  end

  def get_news(_, %{news_id: news_id}, %{context: %{current_user: current_user}}) do
    Social.get_news(news_id)
    |> case do
      nil ->
        {:error, message: "News not found"}

      news ->
        news.community_id
        |> Commune.is_community_member?(current_user.account)
        |> if do
          {:ok, news}
        else
          {:error, message: "User unauthorized"}
        end
    end
  end

  def get_news_versions(%{id: news_id}, _, %{context: %{current_user: current_user}}) do
    if is_admin?(news_id, current_user) do
      versions = Social.get_news_versions(news_id)

      {:ok, versions}
    else
      {:error, message: "Unauthorized"}
    end
  end

  defp is_admin?(news_id, current_user) do
    case Social.get_news(news_id) do
      nil -> false
      news -> Commune.is_community_admin?(news.community_id, current_user.account)
    end
  end
end
