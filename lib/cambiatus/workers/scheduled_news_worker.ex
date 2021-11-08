defmodule Cambiatus.Workers.ScheduledNewsWorker do
  @moduledoc """
  Handles news with scheduling field filled
  """
  use Oban.Worker, queue: :scheduled_news, unique: [fields: [:args, :worker]]

  alias Cambiatus.Commune
  alias Cambiatus.Social

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"news_id" => news_id}}) do
    news = Social.get_news(news_id)

    if !is_nil(news.scheduling) do
      Commune.set_highlighted_news(news.community_id, news.id)

      Absinthe.Subscription.publish(
        CambiatusWeb.Endpoint,
        news,
        highlighted_news: news.community_id
      )
    end

    :ok
  end
end
