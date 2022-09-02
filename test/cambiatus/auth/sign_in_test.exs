defmodule Cambiatus.Auth.SignInTest do
  use Cambiatus.DataCase

  alias Cambiatus.Auth.{SignIn, InvitationId}

  describe "authentication Sign in" do
    setup do
      creator = insert(:user)

      community =
        :community
        |> insert(%{creator: creator.account})
        |> Repo.preload(:subdomain)

      {:ok, %{community: community}}
    end

    test "successful sign in", %{community: community} do
      user = insert(:user)
      insert(:request, user: user)

      assert {:ok, u} = SignIn.sign_in(user.account, "pass", community: community)
      assert u.account == user.account
    end

    test "non existing user sign_in", %{community: community} do
      assert SignIn.sign_in("nonexisting", "", community: community) ==
               {:error, "No user with account: nonexisting found"}
    end

    test "sign in with invitation" do
      community = insert(:community)
      user = insert(:user)
      another_user = insert(:user)
      insert(:request, user: another_user)
      invitation = insert(:invitation, %{community: community, creator: user})
      invitation_id = InvitationId.encode(invitation.id)

      assert {:ok, u} = SignIn.sign_in(another_user.account, "pass", invitation_id: invitation_id)
      assert u.account == another_user.account
    end
  end
end
