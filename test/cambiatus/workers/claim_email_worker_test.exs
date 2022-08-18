defmodule Cambiatus.Workers.ClaimEmailWorkerTest do
  use Cambiatus.DataCase
  use Oban.Testing, repo: Cambiatus.Repo

  import Swoosh.TestAssertions

  alias Cambiatus.Workers.ClaimEmailWorker

  describe "perform/2" do
    test "perform claim email job" do
      user = insert(:user, %{claim_notification: true})
      community = insert(:community)
      objective = insert(:objective, %{community: community})
      action = insert(:action, %{objective: objective})
      claim = insert(:claim, %{claimer: user, action: action})

      assert {:ok, %{}} == perform_job(ClaimEmailWorker, %{"claim_id" => claim.id})

      assert_email_sent(
        to: user.email,
        subject: "Your claim was approved!"
      )
    end
  end
end
