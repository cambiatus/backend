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

    test "send_push/2 sends a  transfer push notification" do
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

    test "notify_validators/1 sends a verification push notification" do
      # Create a push subscription, which has our validator
      push = insert(:push_subscription)

      # create an action to validate
      action = insert(:action)

      # use the validator from above for the action abobe
      insert(:validator, %{action: action, validator: push.account})

      payload = %{
        title: "Claim Verification Request",
        body: action.description,
        type: :verification
      }

      BeSpiral.Notifications.TestAdapter
      |> expect(:send_web_push, fn load, sub ->
        assert load == Jason.encode!(payload)
        assert sub.keys.auth == push.auth_key
        assert sub.keys.p256dh == push.p_key

        {:ok, %{status_code: 201}}
      end)

      assert {:ok, :notified} = Notifications.notify_validators(action)
    end

    test "notify_claimer/1 sends a validation push notification" do
      # create a claim to validate
      claim = insert(:claim)

      # create a push subscription for the claimer
      push = insert(:push_subscription, %{account: claim.claimer})

      payload = %{
        title: "Your claim has recieved a validation",
        body: "",
        type: :validation
      }

      BeSpiral.Notifications.TestAdapter
      |> expect(:send_web_push, fn load, sub ->
        assert load == Jason.encode!(payload)
        assert sub.keys.auth == push.auth_key
        assert sub.keys.p256dh == push.p_key

        {:ok, %{status_code: 201}}
      end)

      assert {:ok, :notified} = Notifications.notify_claimer(claim)
    end

    test "notify_claim_approved/1 sends an approval push notification" do
      claim = insert(:claim)

      push = insert(:push_subscription, %{account: claim.claimer})

      payload = %{
        title: "Your claim has been approved",
        body: "",
        type: :validation
      }

      BeSpiral.Notifications.TestAdapter
      |> expect(:send_web_push, fn load, sub ->
        assert load == Jason.encode!(payload)
        assert sub.keys.auth == push.auth_key
        assert sub.keys.p256dh == push.p_key

        {:ok, %{status_code: 201}}
      end)

      assert {:ok, :notified} = Notifications.notify_claim_approved(claim.id)
    end

    test "notify_mintee/1 notifies a user of currency minted for them" do
      mint = insert(:mint)

      push = insert(:push_subscription, %{account: mint.to})

      payload = %{
        title: "You have received an issue",
        body: "#{mint.quantity}#{mint.community.symbol} has been issued to your account",
        type: :mint
      }

      BeSpiral.Notifications.TestAdapter
      |> expect(:send_web_push, fn load, sub ->
        assert load == Jason.encode!(payload)
        assert sub.keys.auth == push.auth_key
        assert sub.keys.p256dh == push.p_key

        {:ok, %{status_code: 201}}
      end)

      assert {:ok, :notified} = Notifications.notify_mintee(mint)
    end
  end
end
