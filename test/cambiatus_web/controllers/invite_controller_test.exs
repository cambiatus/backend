defmodule CambiatusWeb.InviteControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Auth

  setup %{conn: conn} do
    updated_conn = conn
                  |> put_req_header("accept", "application/json")
                  |> put_req_header("user-agent", "Test agent")
    {:ok, conn: updated_conn}
  end

  describe "Invitations" do
    setup :valid_community_and_user

    test "create a new invitation",
         %{conn: conn} do
      community = insert(:community)
      user = insert(:user)
      insert(:network, %{account: user, community: community})

      body = %{community_id: community.symbol, creator_id: user.account}
      conn = post(conn, invite_path(conn, :invite), body)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      # find invite and validate its information
      {:ok, invitation} = Auth.get_invitation(id)

      assert invitation.community_id == community.symbol
      assert invitation.creator_id == user.account
    end

    test "cannot create invitation from a community you don't belong to",
         %{conn: conn, community: community} do
      user = insert(:user)
      body = %{community_id: community.symbol, creator_id: user.account}
      conn = post(conn, invite_path(conn, :invite), body)

      assert %{"message" => "User don\'t belong to the community"} =
               json_response(conn, 422)["data"]
    end

    test "creating the same invitation twice renders the same id",
         %{conn: conn} do
      community = insert(:community)
      user = insert(:user)
      insert(:network, %{account: user, community: community})

      body = %{"community_id" => community.symbol, "creator_id" => user.account}
      first_conn = post(conn, invite_path(conn, :invite), body)
      assert %{"id" => first_id} = json_response(first_conn, 200)["data"]

      # Second invite creation
      conn = post(conn, invite_path(conn, :invite), body)
      assert %{"id" => second_id} = json_response(conn, 200)["data"]

      assert first_id == second_id
    end
  end
end
