defmodule Cambiatus.Workers.ScheduledNewsWorker do
  @moduledoc """
  Handles news with scheduling field filled - runs every day
  """
  use Oban.Worker, queue: :scheduled_news

  alias Cambiatus.Commune
  alias Cambiatus.Social

  @impl Oban.Worker
  def perform(_job) do
    Social.today_scheduled_news()
    |> Enum.each(fn news ->
      Commune.set_highlighted_news(news.community_id, news.id)
    end)

    :ok
  end
end
