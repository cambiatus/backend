defmodule BeSpiralWeb.Resolvers.NotificationsTests do
  @moduledoc """
  Integration tests for the notifications resolvers
  """
  use BeSpiral.ApiCase

  alias BeSpiral.{
    Notifications.PushSubscription
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
  end
end
