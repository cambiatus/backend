defmodule Cambiatus.Workers.MonthlyDigestWorker do
  @moduledoc """
  Handles monthly news digest
  """
  use Oban.Worker, queue: :monthly_digest

  alias Cambiatus.Commune.Community
  alias Cambiatus.Repo
  alias Cambiatus.Social.News

  def perform(_) do
    Community
    |> Community.with_news_enabled()
    |> Repo.all()
    |> Repo.preload([[news: News.last_thirty_days()], :members])
    |> Enum.each(fn community ->
      unless Enum.empty?(community.news) do
        CambiatusWeb.Email.monthly_digest(community)
      end
    end)
  end
end
