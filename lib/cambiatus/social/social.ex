defmodule Cambiatus.Social do
  @moduledoc """
    The Social context. Handles everything related to news.
  """

  import Ecto.Query

  alias Cambiatus.Repo
  alias Cambiatus.Social.News
  alias Cambiatus.Social.NewsReceipt
  alias Cambiatus.Social.NewsVersion
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

  def get_news(news_id) do
    News
    |> Repo.get(news_id)
  end

  def create_news(attrs \\ %{}) do
    %News{}
    |> News.changeset(attrs)
    |> Repo.insert()
  end

  def update_news_with_history(%News{} = news, attrs) do
    version_params =
      Map.take(news, [:title, :description, :user_id, :scheduling])
      |> Map.put(:news_id, news.id)

    Multi.new()
    |> Multi.update(:news, News.changeset(news, attrs))
    |> Multi.insert(:version, NewsVersion.changeset(%NewsVersion{}, version_params))
    |> Repo.transaction()
  end

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

  def get_news_reactions(news_id) do
    NewsReceipt
    |> NewsReceipt.from_news(news_id)
    |> Repo.all()
    |> Enum.reduce(%{}, &sum_reactions/2)
    |> Enum.map(fn {reaction, count} -> %{reaction: reaction, count: count} end)
  end

  defp sum_reactions(%{reactions: reactions}, %{} = acc) do
    reacts = Enum.into(reactions, %{}, &{&1, 1})

    Map.merge(acc, reacts, fn _k, v1, v2 -> v1 + v2 end)
  end
end