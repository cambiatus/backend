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

      assert :ok ==
               perform_job(ScheduledNewsWorker, %{
                 "news_id" => news.id,
                 "news_scheduling" => news.scheduling
               })

      assert Repo.get(Community, community.symbol).highlighted_news_id == news.id
    end

    test "returns error and doesnot change highlighted news when scheduling does not match" do
      current_highlighted = insert(:news)
      community = insert(:community, highlighted_news: current_highlighted)
      news = insert(:news, scheduling: ~U[2021-11-03 14:15:20.996193Z], community: community)
      other_scheduling = ~U[2021-12-03 20:10:20.996193Z]

      assert {:error, "Scheduling does not match"} ==
               perform_job(ScheduledNewsWorker, %{
                 "news_id" => news.id,
                 "news_scheduling" => other_scheduling
               })

      assert Repo.get(Community, community.symbol).highlighted_news_id == current_highlighted.id
    end
  end
end
