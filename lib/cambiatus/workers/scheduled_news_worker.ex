defmodule Cambiatus.Workers.ScheduledNewsWorker do
  @moduledoc """
  Handles news with scheduling field filled
  """
  use Oban.Worker, queue: :scheduled_news, max_attempts: 1

  alias Cambiatus.Commune
  alias Cambiatus.Social

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"news_id" => news_id, "news_scheduling" => news_scheduling}}) do
    news = Social.get_news(news_id)
    {:ok, time, _} = DateTime.from_iso8601(news_scheduling)

    if DateTime.compare(news.scheduling, time) == :eq do
      Commune.set_highlighted_news(news.community_id, news.id)
      :ok
    else
      {:error, "Scheduling does not match"}
    end
  end
end
