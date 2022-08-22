defmodule Cambiatus.Workers.TransferEmailWorkerTest do
  use Cambiatus.DataCase
  use Oban.Testing, repo: Cambiatus.Repo

  import Swoosh.TestAssertions

  alias Cambiatus.Workers.TransferEmailWorker

  describe "perform/2" do
    test "perform transfer email job" do
      user = insert(:user, %{transfer_notification: true})
      community = insert(:community)
      transfer = insert(:transfer, %{to: user, community: community})

      assert {:ok, %{}} == perform_job(TransferEmailWorker, %{"transfer_id" => transfer.id})

      assert_email_sent(
        to: user.email,
        subject: "You received a new transfer on #{community.name}"
      )
    end
  end
end
