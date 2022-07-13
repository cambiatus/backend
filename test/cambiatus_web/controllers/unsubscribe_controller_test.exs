defmodule CambiatusWeb.UnsubscribeControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

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
      subjects = %{transfer_notification: true, claim_notification: true, digest: true}
      user = insert(:user, subjects)

      token = AuthToken.sign(user, "email")

      available_subjects = Map.keys(subjects)
      picked_subject = Enum.random(available_subjects)
      other_subjects = List.delete(available_subjects, picked_subject)

      path = "/api/unsubscribe/sub:#{picked_subject}/#{token}"

      response = post(conn, path, "List-Unsubscribe=One-Click")

      assert response.status == 200
      # Assert that only the chosen subject was modified
      assert Map.get(user, picked_subject) == false
      assert Enum.all?(other_subjects, &Map.get(user, &1))
    end
  end
end
