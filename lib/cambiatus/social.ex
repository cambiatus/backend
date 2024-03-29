defmodule Cambiatus.Social do
  @moduledoc """
    The Social context. Handles everything related to news.
  """

  import Ecto.Query

  alias Cambiatus.Commune
  alias Cambiatus.Repo
  alias Cambiatus.Social.News
  alias Cambiatus.Social.NewsReceipt
  alias Cambiatus.Social.NewsVersion
  alias Cambiatus.Workers.ScheduledNewsWorker
  alias Ecto.Multi

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(News, _params) do
    News
    |> order_by([n], desc: n.inserted_at)
  end

  def query(queryable, _params) do
    queryable
  end

  def get_news(news_id), do: Repo.get(News, news_id)

  def create_news(attrs \\ %{}) do
    %News{}
    |> News.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, news} ->
        handle_highlighted_news(news)
        {:ok, news}

      error ->
        error
    end
  end

  def handle_highlighted_news(%News{scheduling: nil} = news),
    do: Commune.set_highlighted_news(news.community_id, news.id)

  def handle_highlighted_news(%News{} = news) do
    %{news_id: news.id}
    |> ScheduledNewsWorker.new(scheduled_at: news.scheduling, replace: [:scheduled_at])
    |> Oban.insert()
  end

  def update_news_with_history(%News{} = news, attrs) do
    version_params =
      Map.take(news, [:title, :description, :user_id, :scheduling])
      |> Map.put(:news_id, news.id)

    Multi.new()
    |> Multi.update(:news, News.changeset(news, attrs))
    |> Multi.insert(:version, NewsVersion.changeset(%NewsVersion{}, version_params))
    |> set_scheduling_worker(news.id, attrs)
    |> Repo.transaction()
  end

  defp set_scheduling_worker(%Multi{} = multi, _, %{scheduling: nil}), do: multi

  defp set_scheduling_worker(%Multi{} = multi, news_id, %{scheduling: scheduling}) do
    multi
    |> Oban.insert(
      :scheduling_worker,
      ScheduledNewsWorker.new(%{news_id: news_id},
        scheduled_at: scheduling,
        replace: [:scheduled_at]
      )
    )
  end

  defp set_scheduling_worker(%Multi{} = multi, _, _), do: multi

  def upsert_news_receipt(news_id, user_account, reactions \\ []) do
    params = %{news_id: news_id, user_id: user_account, reactions: reactions}

    Repo.get_by(NewsReceipt, news_id: news_id, user_id: user_account)
    |> case do
      nil -> %NewsReceipt{}
      receipt -> receipt
    end
    |> NewsReceipt.changeset(params)
    |> Repo.insert_or_update()
  end

  def get_news_versions(news_id) do
    NewsVersion
    |> NewsVersion.from_news(news_id)
    |> Repo.all()
  end

  def get_news_reactions(news_id) do
    NewsReceipt
    |> NewsReceipt.from_news(news_id)
    |> Repo.all()
    |> Enum.reduce(%{}, &sum_reactions/2)
    |> Enum.map(fn {reaction, count} -> %{reaction: reaction, count: count} end)
  end

  def get_news_receipt_from_user(news_id, user_id) do
    NewsReceipt
    |> NewsReceipt.from_news(news_id)
    |> NewsReceipt.from_user(user_id)
    |> Repo.one()
  end

  defp sum_reactions(%{reactions: reactions}, %{} = acc) do
    reacts = Enum.into(reactions, %{}, &{&1, 1})

    Map.merge(acc, reacts, fn _k, v1, v2 -> v1 + v2 end)
  end

  def news_from_community?(news_id, community_id) do
    Repo.get_by(News, %{id: news_id, community_id: community_id})
    |> case do
      nil -> false
      _ -> true
    end
  end

  def delete_news(news_id, current_user) do
    with {:news, news} <- {:news, get_news(news_id)},
         {:admin, true} <-
           {:admin, Commune.is_community_admin?(news.community_id, current_user.account)},
         news <- Repo.preload(news, [:community, :versions]),
         {:is_highlighted, false} <-
           {:is_highlighted, news.community.highlighted_news_id == news.id} do
      case Repo.delete(news) do
        {:ok, _} -> {:ok, "News deleted successfully"}
        _ -> {:error, "News delete failed"}
      end
    else
      {:news, nil} ->
        {:error, "News not found"}

      {:admin, false} ->
        {:error, "Logged user can't do that action"}

      {:is_highlighted, true} ->
        {:error, "Can't delete highlighted news"}
    end
  end
end
