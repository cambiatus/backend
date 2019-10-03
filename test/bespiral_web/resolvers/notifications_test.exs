defmodule BeSpiralWeb.Resolvers.NotificationsTests do
  @moduledoc """
  Integration tests for the notifications resolvers
  """
  use BeSpiral.ApiCase

  alias BeSpiral.{
    Notifications.PushSubscription,
    Notifications.NotificationHistory
  }

  describe "Notifications resolvers" do
    test "creates a push subscription from the GraphQL endpoint", %{conn: conn} do
      assert Repo.aggregate(PushSubscription, :count, :id) == 0

      user = insert(:user)

      query = """
      mutation($input: PushSubscriptionInput) {
        registerPush(input: $input) {
          accountId
        }
      }
      """

      variables = %{
        "input" => %{
          "account" => user.account,
          "p_key" => "some-p-key",
          "auth_key" => "some-auth",
          "endpoint" => "some-endpoint"
        }
      }

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "registerPush" => pushed_account
        }
      } = json_response(res, 200)

      assert Repo.aggregate(PushSubscription, :count, :id) == 1

      assert pushed_account["accountId"] == user.account
    end

    @num 3
    test "collects number of unread notifications for a user", %{conn: conn} do
      assert Repo.aggregate(NotificationHistory, :count, :id) == 0

      user = insert(:user)

      _ =
        1..@num
        |> Enum.map(fn _ ->
          insert(:notification_history, %{is_read: true, recipient: user})
        end)

      unread_histories =
        1..@num
        |> Enum.map(fn _ ->
          insert(:notification_history, %{recipient: user})
        end)

      assert Repo.aggregate(NotificationHistory, :count, :id) == @num * 2

      query = """
      query($input: UnreadNotificationsInput!) {
        unreadNotifications(input: $input) {
          count 
        }
      }
      """

      variables = %{
        "input" => %{
          "account" => user.account
        }
      }

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "unreadNotifications" => unread
        }
      } = json_response(res, 200)

      assert unread["count"] == Enum.count(unread_histories)
    end
  end
end
