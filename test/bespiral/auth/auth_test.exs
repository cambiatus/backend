defmodule BeSpiral.AuthTest do
  use BeSpiral.DataCase

  alias BeSpiral.Auth

  describe "authentication Sign in" do
    setup :valid_community_and_user

    test "successful sign in", %{user: user} do
      assert {:ok, u} = Auth.sign_in(%{"account" => user.account})
      assert u.account == user.account
    end

    test "non existing user sign_in" do
      assert Auth.sign_in(%{"account" => "nonexisting"}) == {:error, :not_found}
    end
  end

  describe "authentication Sign up" do
    setup :valid_community_and_user

    alias BeSpiral.Commune

    test "successful sign up with minimum params" do
      account = "testesttes2"
      assert {:ok, user} = Auth.sign_up(%{"account" => account})
      assert user.account == account
    end

    test "successful sign up with all params" do
      account = "testesttes3"

      assert {:ok, user} =
               Auth.sign_up(%{"account" => account, "name" => "name", "email" => "name@email"})

      assert user.email == "name@email"
      assert user.name == "name"
    end

    test "sign up with user already registred", %{user: user} do
      assert Auth.sign_up(%{"account" => user.account}) ==
               {:error, :user_already_registered}
    end

    test "sign up with user already registred and with invitation", %{user: user} do
      # Create invitation
      invitation = insert(:invitation)

      auth_params = %{
        "account" => user.account,
        "name" => "name",
        "invitation_id" => invitation.id
      }

      assert Auth.sign_up(auth_params) == {:error, :user_already_registered}
    end

    test "sign up with invalid invitation", %{user: user} do
      auth_params = %{
        "account" => user.account,
        "name" => "name",
        "email" => "something@email.com",
        "invitation_id" => 0
      }

      assert Auth.sign_up(auth_params) == {:error, :not_found}
    end

    test "sign up with invitation", %{community: community, user: user} do
      new_user_email = "t@test.local"
      new_user_account_name = "tnewuser"
      invitation = insert(:invitation, %{community: community, creator: user})

      {:ok, new_user} =
        Auth.sign_up(%{
          "account" => new_user_account_name,
          "name" => "name",
          "email" => new_user_email,
          "invitation_id" => invitation.id
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

    @invalid_attrs %{community: nil, creator: nil}

    test "list_invitations/0 returns all invitations" do
      invitation = insert(:invitation)
      assert Auth.list_invitations() == [invitation]
    end

    test "get_invitation!/1 returns the invitation with given id" do
      invitation = insert(:invitation)
      found_invitation = Auth.get_invitation!(invitation.id)

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

    test "create_invitation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auth.create_invitation(@invalid_attrs)
    end

    test "change_invitation/1 returns a invitation changeset" do
      invitation = insert(:invitation)

      assert %Ecto.Changeset{} = Auth.change_invitation(invitation)
    end
  end
end
