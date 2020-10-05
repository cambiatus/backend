defmodule Cambiatus.AuthTest do
  use Cambiatus.DataCase

  alias Cambiatus.{
    Auth,
    Auth.InvitationId
  }

  describe "authentication Sign in" do
    setup :valid_community_and_user

    test "successful sign in", %{user: user} do
      assert {:ok, u} = Auth.sign_in(%{"account" => user.account})
      assert u.account == user.account
    end

    test "non existing user sign_in" do
      assert Auth.sign_in(%{"account" => "nonexisting"}) == {:error, :not_found}
    end

    test "sign in with invitation" do
      community = insert(:community)
      user = insert(:user)
      another_user = insert(:user)
      invitation = insert(:invitation, %{community: community, creator: user})
      invitation_id = invitation.id |> Cambiatus.Auth.InvitationId.encode()

      body = %{
        "account" => another_user.account
      }

      assert {:ok, u} = Auth.sign_in(body, invitation_id)
      assert u.account == another_user.account
    end
  end

  describe "authentication Sign up" do
    setup :valid_community_and_user

    alias Cambiatus.Commune

    test "successful sign up with minimum params" do
      account = "loremlorem15"
      params = %{account: account, name: "somename", email: "some@email", public_key: "anykey"}
      assert {:ok, user} = Auth.sign_up(params)
      assert user.account == account
    end

    test "successful sign up with all params" do
      account = "loremlorem31"

      assert {:ok, user} =
               Auth.sign_up(%{
                 account: account,
                 name: "name",
                 email: "name@email",
                 public_key: "pubkey"
               })

      assert user.email == "name@email"
      assert user.name == "name"
    end

    test "sign up with user already registred", %{user: user} do
      params = %{account: user.account, name: "anyname", email: "anyemail", public_key: "anykey"}
      assert {:error, :user_already_registered} = Auth.sign_up(params)
    end

    test "sign up with user already registred and with invitation", %{user: user} do
      # Create invitation
      invitation = insert(:invitation)

      auth_params = %{
        account: user.account,
        name: "name",
        email: user.email,
        public_key: "publickey",
        invitation_id: InvitationId.encode(invitation.id)
      }

      assert {:error, :user_already_registered} = Auth.sign_up(auth_params)
    end

    test "sign up with invalid invitation", %{user: user} do
      auth_params = %{
        "account" => user.account,
        "name" => "name",
        "email" => "something@email.com",
        "invitation_id" => "",
        "public_key" => "mykey"
      }

      assert Auth.sign_up(auth_params) == {:error, :invitation_not_found}
    end

    test "sign up with invitation" do
      community = insert(:community)
      user = insert(:user)
      invitation = insert(:invitation, %{community: community, creator: user})

      new_user_email = "t@test.local"
      new_user_account_name = "loremlorem13"

      {:ok, new_user} =
        Auth.sign_up(%{
          "account" => new_user_account_name,
          "name" => "name",
          "email" => new_user_email,
          "invitation_id" => InvitationId.encode(invitation.id),
          "public_key" => "mykey"
        })

      assert(new_user.email == new_user_email)
      assert(new_user.account == new_user_account_name)
      assert(new_user.name == "name")

      # check if user belongs to the community
      community.symbol
      |> Commune.list_community_network()
      |> Enum.any?(&(Map.get(&1, :account_id) == new_user_account_name))
      |> assert
    end
  end

  describe "invitations" do
    setup :valid_community_and_user

    test "list_invitations/0 returns all invitations" do
      invitation = insert(:invitation)
      assert Auth.list_invitations() == [invitation]
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

      assert res == {:error, "Something went wrong while decoding the hashid"}
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
