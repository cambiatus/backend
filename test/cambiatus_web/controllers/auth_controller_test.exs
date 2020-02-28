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
  end

  describe "sign up" do
    alias Cambiatus.Auth

    setup :valid_community_and_user

    test "successful sign up", %{conn: conn} do
      conn = post(conn, auth_path(conn, :sign_up), %{user: %{account: "totallynew"}})
      assert json_response(conn, 200)["data"]["user"]["account"] == "totallynew"
    end

    test "sign up with invitation", %{conn: conn} do
      community = insert(:community)
      user = insert(:user)
      insert(:network, %{account: user, community: community})

      invite_params = %{
        "community_id" => community.symbol,
        "creator_id" => user.account
      }

      assert {:ok, invitation} = Auth.create_invitation(invite_params)

      sign_up_params = %{
        user: %{
          account: "newaccount",
          invitation_id: invitation.id,
          name: "name"
        }
      }

      conn = post(conn, auth_path(conn, :sign_up), sign_up_params)
      assert json_response(conn, 200)["data"]["user"]["account"] == "newaccount"
    end

    test "sign up with existing user", %{conn: conn, user: user} do
      conn = post(conn, auth_path(conn, :sign_up), %{user: %{account: user.account}})
      assert conn.status == 401
    end

    test "sign up with invalid params", %{conn: conn} do
      assert_error_sent(400, fn ->
        post(conn, auth_path(conn, :sign_up), %{user: %{account: 1}})
      end)
    end
  end
end
