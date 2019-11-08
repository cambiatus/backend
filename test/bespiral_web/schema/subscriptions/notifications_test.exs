defmodule BeSpiralWeb.Schema.Subscriptions.NotificationsTest do
  use BeSpiralWeb.SubscriptionCase

  alias BeSpiral.Notifications.NotificationHistory

  describe "Notifications Subscriptions" do
    @num 3
    test "Can be subscribed to", %{socket: socket} do
      user = insert(:user)

      unread_notifications =
        insert_list(@num, :notification_history, %{recipient: user, is_read: false})

      read_notifications =
        insert_list(@num * 2, :notification_history, %{recipient: user, is_read: true})

      assert Repo.aggregate(NotificationHistory, :count, :id) ==
               Enum.count(unread_notifications) + Enum.count(read_notifications)

      subscription = """
      subscription($input: UnreadNotificationsSubscriptionInput!) {
        unreads(input: $input) {
         unreads
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

      payload = %{unreads: Enum.count(unread_notifications)}

      # Publish our subscription 
      Absinthe.Subscription.publish(BeSpiralWeb.Endpoint, payload, unreads: user.account)

      expected_payload = %{"unreads" => Enum.count(unread_notifications)}

      expected_result = %{
        result: %{data: %{"unreads" => expected_payload}},
        subscriptionId: subscription_id
      }

      assert_push("subscription:data", push)
      assert expected_result == push
    end
  end
end
