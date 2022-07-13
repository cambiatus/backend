defmodule CambiatusWeb.Resolvers.Social do
  @moduledoc """
  This module holds the implementation of the resolver for the Social context
  use this to resolve any queries and mutations for Social
  """

  alias Cambiatus.{Commune, Social}

  def upsert_news(_, %{id: news_id} = params, %{
        context: %{current_user: current_user, current_community: current_community}
      }) do
    params =
      Map.merge(params, %{user_id: current_user.account, commmunity_id: current_community.symbol})

    with news <- Social.get_news(news_id),
         {:ok, transaction} <- Social.update_news_with_history(news, params) do
      {:ok, transaction.news}
    else
      nil ->
        {:error, "News not found", details: nil}

      {:error, error} ->
        Sentry.capture_message("News update failed", extra: %{error: error})
        {:error, message: "Could not update news", details: Cambiatus.Error.from(error)}

      {:error, _, error, _} ->
        Sentry.capture_message("News update failed", extra: %{error: error})
        {:error, message: "Could not update news", details: Cambiatus.Error.from(error)}
    end
  end

  def upsert_news(_, params, %{
        context: %{current_user: current_user, current_community: current_community}
      }) do
    params
    |> Map.merge(%{user_id: current_user.account, community_id: current_community.symbol})
    |> Social.create_news()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("News creation failed", extra: %{error: reason})
        {:error, message: "Could not create news", details: Cambiatus.Error.from(reason)}

      {:ok, news} ->
        if news.scheduling != nil do
          Absinthe.Subscription.publish(CambiatusWeb.Endpoint, news,
            highlighted_news: news.community_id
          )
        end

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

  def get_news_receipt_from_user(%{id: news_id}, _, %{context: %{current_user: current_user}}) do
    news_receipt = Social.get_news_receipt_from_user(news_id, current_user.account)

    {:ok, news_receipt}
  end

  def delete_news(_, %{news_id: news_id}, %{context: %{current_user: current_user}}) do
    case Social.delete_news(news_id, current_user) do
      {:error, reason} ->
        Sentry.capture_message("News deletion failed", extra: %{error: reason})

        {:ok, %{status: :error, reason: reason}}

      {:ok, message} ->
        {:ok, %{status: :success, reason: message}}
    end
  end

  defp is_admin?(news_id, current_user) do
    case Social.get_news(news_id) do
      nil -> false
      news -> Commune.is_community_admin?(news.community_id, current_user.account)
    end
  end
end
