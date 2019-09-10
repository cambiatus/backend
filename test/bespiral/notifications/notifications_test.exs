defmodule BeSpiral.NotificationsTest do
  @moduledoc """
  Integration tests for the functions in the `BeSpiral.Notifications` context
  """
  use BeSpiral.DataCase
  import BeSpiral.Factory
  import Mox

  alias BeSpiral.{
    Notifications,
    Notifications.PushSubscription
  }

  describe "Notifications Context" do
    test "add_push_subscription/2 creates a PushSubscription for a user" do
      user = insert(:user)

      params = %{
        auth_key: "long-rand",
        p_key: "hectic-key",
        endpoint: "some-url"
      }

      assert Repo.aggregate(PushSubscription, :count, :id) == 0

      {:ok, _} = Notifications.add_push_subscription(user, params)

      assert Repo.aggregate(PushSubscription, :count, :id) == 1

      sub = Repo.one(PushSubscription)

      assert sub.account_id == user.account
    end

    @num 5
    test "get_subscriptions/1 collects a users push subscriptions" do
      user = insert(:user)

      insert_list(@num, :push_subscription, %{account: user})

      {:ok, subs} = Notifications.get_subscriptions(user)

      assert Enum.count(subs) == @num
    end

    test "send_push/2 sends a push notification" do
      push = insert(:push_subscription)

      payload = %{
        title: "Transfer from Zacck",
        body: "Incoming transfer from Zacck of 3 BES",
        type: :transfer
      }

      BeSpiral.Notifications.TestAdapter
      |> expect(:send_web_push, fn load, sub ->
        assert load == Jason.encode!(payload)
        assert sub.keys.auth == push.auth_key
        assert sub.keys.p256dh == push.p_key

        {:ok, %{status_code: 201}}
      end)

      assert {:ok, %{status_code: 201}} = Notifications.send_push(payload, push)
    end
  end
end
