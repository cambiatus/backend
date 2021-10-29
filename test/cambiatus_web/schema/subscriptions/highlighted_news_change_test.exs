defmodule CambiatusWeb.Schema.Subscriptions.HighlightedNewsChangeTest do
  use CambiatusWeb.SubscriptionCase

  alias CambiatusWeb.Endpoint

  describe "HighlightedNewsChange Subscription" do
    @tag :authenticated_socket
    test "subscribes to highlighted news changes successfully", %{socket: socket} do
      community = insert(:community)
      news = insert(:news, community: community, title: "Hello world")

      subscription = """
      subscription {
        highlightedNewsChange(communityId: "#{community.symbol}") {
          id
          title
        }
      }
      """

      ref = push_doc(socket, subscription)
      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Absinthe.Subscription.publish(Endpoint, news, highlighted_news_change: community.symbol)

      expected_payload = %{"id" => news.id, "title" => "Hello world"}

      expected_result = %{
        result: %{data: %{"highlightedNewsChange" => expected_payload}},
        subscriptionId: subscription_id
      }

      assert_push("subscription:data", push)
      assert expected_result == push
    end

    test "returns error when not logged in", %{socket: socket} do
      community = insert(:community)

      subscription = """
      subscription {
        highlightedNewsChange(communityId: "#{community.symbol}") {
          id
          title
        }
      }
      """

      ref = push_doc(socket, subscription)
      assert_reply(ref, :error, %{errors: [%{message: "Please login first"}]})
    end
  end
end
