defmodule Cambiatus.Workers.MonthlyDigestWorkerTest do
  use Cambiatus.DataCase
  use Oban.Testing, repo: Cambiatus.Repo

  alias Cambiatus.Workers.MonthlyDigestWorker
  alias Cambiatus.Workers.DigestEmailWorker

  describe "perform/1" do
    test "sends emails to all users from all communities with news" do
      community1 = insert(:community, has_news: true)
      community2 = insert(:community, has_news: true)
      community3 = insert(:community, has_news: false)
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)
      user4 = insert(:user)
      insert(:network, user: user1, community: community1)
      insert(:network, user: user2, community: community1)
      insert(:network, user: user2, community: community2)
      insert(:network, user: user3, community: community2)
      insert(:network, user: user4, community: community3)

      insert(:news, community: community1)
      insert(:news, community: community2)

      assert {:ok, _} = perform_job(MonthlyDigestWorker, %{})

      assert_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community1.symbol, account: user1.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community2.symbol, account: user1.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community3.symbol, account: user1.account}
      )

      assert_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community1.symbol, account: user2.account}
      )

      assert_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community2.symbol, account: user2.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community3.symbol, account: user2.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community1.symbol, account: user3.account}
      )

      assert_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community2.symbol, account: user3.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community3.symbol, account: user3.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community1.symbol, account: user4.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community2.symbol, account: user4.account}
      )

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community3.symbol, account: user4.account}
      )
    end

    test "emails won't be sent if user has disabled digest" do
      community = insert(:community, has_news: true)

      insert(:news, community: community)

      user = insert(:user, digest: false)
      insert(:network, user: user, community: community)

      assert {:ok, _} = perform_job(MonthlyDigestWorker, %{})

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community.symbol, account: user.account}
      )
    end

    test "emails won't be sent if community does not have news in last 30 days" do
      community = insert(:community, has_news: true)
      user = insert(:user)
      insert(:network, user: user, community: community)

      insert(:news,
        community: community,
        updated_at: DateTime.utc_now() |> DateTime.add(-3600 * 24 * 32, :second)
      )

      insert(:news,
        community: community,
        updated_at: DateTime.utc_now() |> DateTime.add(-3600 * 24 * 40, :second)
      )

      assert {:ok, _} = perform_job(MonthlyDigestWorker, %{})

      refute_enqueued(
        worker: DigestEmailWorker,
        args: %{community_id: community.symbol, account: user.account}
      )
    end
  end
end
