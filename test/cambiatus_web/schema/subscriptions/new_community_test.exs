defmodule CambiatusWeb.Schema.Subscriptions.NewCommunityTest do
  use CambiatusWeb.SubscriptionCase

  describe "New Community Subscription" do
    test "Can be subscribed to", %{socket: socket} do
      community = insert(:community)

      subscription = """
      subscription($input: NewCommunityInput!) {
        newcommunity(input: $input) {
          symbol
        }
      }
      """

      variables = %{
        "input" => %{
          "symbol" => community.symbol
        }
      }

      ref = push_doc(socket, subscription, variables: variables)

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      # Publish our subscription
      Absinthe.Subscription.publish(CambiatusWeb.Endpoint, community,
        newcommunity: community.symbol
      )

      expected_payload = %{"symbol" => community.symbol}

      expected_result = %{
        result: %{data: %{"newcommunity" => expected_payload}},
        subscriptionId: subscription_id
      }

      assert_push("subscription:data", push)
      assert expected_result == push
    end
  end
end
