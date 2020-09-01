defmodule CambiatusWeb.AuthControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "sign in" do
    setup :valid_community_and_user

    test "successful sign in", %{conn: conn, user: user} do
      conn = post(conn, auth_path(conn, :sign_in), %{user: %{account: user.account}})
      assert json_response(conn, 200)["data"]["user"]["account"] == user.account
    end

    test "non existing user sign in", %{conn: conn} do
      conn = post(conn, auth_path(conn, :sign_in), %{user: %{account: "nonexisting"}})
      assert conn.status == 404
    end

    test "sign in with invalid params", %{conn: conn} do
      assert_error_sent(400, fn ->
        post(conn, auth_path(conn, :sign_in), %{account: 1})
      end)
    end

    test "sign in with invitation", %{conn: conn, user: user} do
      invite = insert(:invitation, %{creator: user})
      invite_id = invite.id |> Cambiatus.Auth.InvitationId.encode()
      body = %{user: %{account: user.account}, invitation_id: invite_id}
      conn = post(conn, auth_path(conn, :sign_in), body)
      assert json_response(conn, 200)["data"]["user"]["account"] == user.account
    end
  end
end
