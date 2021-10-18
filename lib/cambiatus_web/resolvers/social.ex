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
    Social.get_news_reactions(news_id)
    |> case do
      nil -> {:error, message: "Reactions not found"}
      reactions -> {:ok, reactions}
    end
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
end
