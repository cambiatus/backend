defmodule Cambiatus.Workers.ScheduledNewsWorkerTest do
  use Cambiatus.DataCase
  use Oban.Testing, repo: Cambiatus.Repo

  alias Cambiatus.Commune.Community
  alias Cambiatus.Workers.ScheduledNewsWorker

  describe "perform/2" do
    test "sets highlighted news when scheduling matches current news scheduling" do
      current_highlighted = insert(:news)
      community = insert(:community, highlighted_news: current_highlighted)
      news = insert(:news, scheduling: ~U[2021-11-03 14:15:20.996193Z], community: community)

      assert :ok == perform_job(ScheduledNewsWorker, %{"news_id" => news.id})

      assert Repo.get(Community, community.symbol).highlighted_news_id == news.id
    end
  end
end
