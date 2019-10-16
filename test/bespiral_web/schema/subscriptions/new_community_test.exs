defmodule BeSpiralWeb.Schema.Subscriptions.NewCommunityTest do 
  use BeSpiralWeb.SubscriptionCase

  describe "New Community Subscription" do 
    test "Can be subscribed to", %{socket: socket} do
      community  = insert(:community)

      subscription = """
      subscription($input: NewCommunityInput!) {
        newCommunity(input: $input) {
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

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      # Publish our subscription 
      Absinthe.Subscription.publish(BeSpiralWeb.Endpoint, community, new_community: community.symbol)

      expected_payload = %{ "symbol" => community.symbol }

      expected_result = %{
        result: %{data: %{"newCommunity" => expected_payload}},
        subscriptionId: subscription_id
      }

      assert_push "subscription:data", push 
      assert expected_result == push
    end
  end 
end 
