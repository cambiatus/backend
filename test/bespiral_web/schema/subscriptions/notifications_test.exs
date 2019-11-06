defmodule BeSpiralWeb.Schema.Subscriptions.NotificationsTest do
  use BeSpiralWeb.SubscriptionCase

  describe "Notifications Subscriptions" do
    test "Can be subscribed to", %{socket: socket} do
      user = insert(:user)

      notification = insert(:notification_history)

      subscription = """
      subscription($input: NotificationsSubscriptionInput!) {
        notifications(input: $input) {
         type
        }
      }
      """

      variables = %{
        "input" => %{
          "account" => user.account
        }
      }

      ref = push_doc(socket, subscription, variables: variables)

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      # Publish our subscription 
      Absinthe.Subscription.publish(BeSpiralWeb.Endpoint, notification,
        notifications: user.account
      )

      expected_payload = %{"notifications" => user.account}

      expected_result = %{
        result: %{data: %{"notifications" => expected_payload}},
        subscriptionId: subscription_id
      }

      assert_push("subscription:data", push)
      assert expected_result == push
    end
  end
end
