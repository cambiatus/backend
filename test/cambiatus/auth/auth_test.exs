defmodule Cambiatus.AuthTest do
  use Cambiatus.DataCase

  alias Cambiatus.{Auth, Auth.InvitationId}

  describe "invitations" do
    setup :valid_community_and_user

    test "list_invitations/0 returns all invitations" do
      invitation = insert(:invitation)
      [found_invitation] = Auth.list_invitations()

      assert found_invitation.id == invitation.id
    end

    test "get_invitation!/1 returns the invitation with given id" do
      invitation = insert(:invitation)
      public_invitation_id = InvitationId.encode(invitation.id)
      found_invitation = Auth.get_invitation!(public_invitation_id)

      assert found_invitation.id == invitation.id
      assert found_invitation.creator_id == invitation.creator_id
      assert found_invitation.community_id == invitation.community_id
    end

    test "create_invitation/1 with valid data creates a invitation",
         %{
           community: community,
           user: user
         } do
      invitation = insert(:invitation, %{community: community, creator: user})

      assert invitation.community_id == community.symbol
      assert invitation.creator_id == user.account
    end

    test "get_invitation! accepts strings and returns the correct invitation" do
      invitation = insert(:invitation)

      found_invitation =
        Auth.get_invitation!(invitation.id |> Cambiatus.Auth.InvitationId.encode())

      assert invitation.id == found_invitation.id
    end

    test "get_invitation accepts strings and returns the correct invitation" do
      invitation = insert(:invitation)

      {:ok, found_invitation} =
        Auth.get_invitation(invitation.id |> Cambiatus.Auth.InvitationId.encode())

      assert invitation.id == found_invitation.id
    end

    test "get_invitation returns appropriate error message with invalid invitation" do
      res = Auth.get_invitation("someincorrectid")

      assert res == {:error, "Invitation not found"}
    end

    test "create_invitation/1 with invalid data returns error changeset" do
      assert {:error, "Can't parse arguments"} = Auth.create_invitation(%{})
    end

    test "change_invitation/1 returns a invitation changeset" do
      invitation = insert(:invitation)

      assert %Ecto.Changeset{} = Auth.change_invitation(invitation)
    end
  end
end
