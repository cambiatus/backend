defmodule CambiatusWeb.InviteControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  setup %{conn: conn} do
    {:ok, put_req_header(conn, "accept", "application/json")}
  end

  describe "Invitations" do
    # test "create a new invitation", %{conn: conn} do
    #   user = insert(:user)
    #   community = insert(:community, %{creator: user})
    #   body = %{community_id: community.id, creator: user.account}
    #   require IEx
    #   IEx.pry()
    #   conn = post(conn, invite_path(conn, :invite), body)
    #   # assert json_response(conn, 200)["data"]

    #   # assert the community and creator are correct
    # end

    # test "cannot create invitation from a community you don't belong to"
  end
end
