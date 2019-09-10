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

    test "sign up with user already registred and with invitation", %{
      user: user,
      another_user: another_user,
      community: community
    } do
      # Create invitation
      invite_params = %{
        community: community.symbol,
        invitee_email: user.email,
        inviter: another_user.account
      }

      assert {:ok, invitation} = Auth.create_invitation(invite_params)

      auth_params = %{
        "account" => user.account,
        "name" => "name",
        "invitation_id" => invitation.id
      }

      assert Auth.sign_up(auth_params) == {:error, :user_already_registered}
    end

    test "sign up with invalid invitation", %{user: user} do
      auth_params = %{"account" => user.account, "name" => "name", "invitation_id" => 0}
      assert Auth.sign_up(auth_params) == {:error, :not_found}
    end

    test "sign up with invitation", %{community: community, user: user} do
      new_user_email = "t@test.local"

      {:ok, %{id: invitation_id}} =
        %{
          community: community.symbol,
          invitee_email: new_user_email,
          inviter: user.account
        }
        |> Auth.create_invitation()

      new_user_account_name = "tnewuser"

      {:ok, new_user} =
        Auth.sign_up(%{
          "account" => new_user_account_name,
          "name" => "name",
          "invitation_id" => invitation_id
        })

      assert(new_user.email == new_user_email)
      assert(new_user.account == new_user_account_name)
      assert(new_user.name == "name")

      # check if user belongs to the community
      community.symbol
      |> Commune.list_community_network()
      |> Enum.any?(&(Map.get(&1, :account_id) == new_user_account_name))
      |> assert

      # Check if invitation is accepted
      assert %{accepted: true} = Auth.get_invitation!(invitation_id)
    end

    test "fails when reusing invitation", %{community: community, user: user} do
      {:ok, invitation} =
        %{
          community: community.symbol,
          invitee_email: "another_name@email.com",
          inviter: user.account
        }
        |> Auth.create_invitation()

      {:ok, _} = Auth.update_invitation(invitation, %{accepted: true})

      assert {:error, _} =
               Auth.sign_up(%{
                 "account" => "asdf",
                 "name" => "name",
                 "invitation_id" => invitation.id
               })
    end
  end

  describe "invitations" do
    setup :valid_community_and_user

    alias BeSpiral.Auth.Invitation

    @valid_attrs %{accepted: true, invitee_email: "invitee@email.com"}
    @update_attrs %{accepted: false}
    @invalid_attrs %{accepted: nil, community: nil, invitee_email: nil, inviter: nil}

    def invitation_fixture(attrs \\ %{}) do
      attrs
      |> Enum.into(@valid_attrs)
      |> Auth.create_invitation()
    end

    test "list_invitations/0 returns all invitations", %{community: community, user: user} do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert Auth.list_invitations() == [invitation]
    end

    test "get_invitation!/1 returns the invitation with given id", %{
      community: community,
      user: user
    } do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert Auth.get_invitation!(invitation.id) == invitation
    end

    test "create_invitation/1 with valid data creates a invitation", %{
      community: community,
      user: user
    } do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert invitation.accepted == true
      assert invitation.community == community.symbol
      assert invitation.invitee_email == "invitee@email.com"
      assert invitation.inviter == user.account
    end

    test "create_invitation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auth.create_invitation(@invalid_attrs)
    end

    test "update_invitation/2 with valid data updates the invitation", %{
      community: community,
      user: user
    } do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert {:ok, invitation} = Auth.update_invitation(invitation, @update_attrs)
      assert %Invitation{} = invitation
    end

    test "update_invitation/2 with invalid data returns error changeset", %{
      community: community,
      user: user
    } do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert {:error, %Ecto.Changeset{}} = Auth.update_invitation(invitation, @invalid_attrs)
    end

    test "change_invitation/1 returns a invitation changeset", %{community: community, user: user} do
      assert {:ok, invitation} =
               invitation_fixture(%{community: community.symbol, inviter: user.account})

      assert %Ecto.Changeset{} = Auth.change_invitation(invitation)
    end
  end
end
