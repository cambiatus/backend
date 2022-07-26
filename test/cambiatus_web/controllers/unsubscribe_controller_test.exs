defmodule CambiatusWeb.UnsubscribeControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Accounts
  alias CambiatusWeb.AuthToken

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Authorization" do
    test "authorize email unsubscription token" do
      user = insert(:user)

      token = AuthToken.sign(user, "email")

      assert {:ok, %{id: _}} = AuthToken.verify(token, "email")
    end

    test "email token is not authorized for regular use" do
      user = insert(:user)

      token = AuthToken.sign(user, "email")

      assert {:error, :invalid} = AuthToken.verify(token)
    end
  end

  describe "Unsubcription" do
    test "unsubscribe using one click functionality",
         %{conn: conn} do
      lists = %{transfer_notification: true, claim_notification: true, digest: true}
      user = insert(:user, lists)

      token = AuthToken.sign(user, "email")

      path = "/api/unsubscribe?token=#{token}"

      response =
        conn
        |> put_req_header("content-type", "text/html")
        |> post(path, "List-Unsubscribe=One-Click")

      assert response.status == 200

      {:ok, user} = Accounts.get_account_profile(user.account)
      keys = Map.keys(lists)
      # Ensure that all email preferences are false
      refute Enum.any?(keys, &Map.get(user, &1))
    end
  end
end
