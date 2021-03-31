defmodule Cambiatus.AccountsTest do
  use Cambiatus.DataCase

  alias Cambiatus.Accounts
  alias Cambiatus.Accounts.Contact

  describe "users" do
    alias Cambiatus.Accounts.User

    @valid_contact_attrs %{user_id: "testtesttest", type: :phone, external_id: "50625233600"}
    @valid_telegram_attrs %{user_id: "testtesttest", type: :telegram, external_id: "https://t.me/janedoe"}
    @valid_instagram_attrs %{user_id: "testtesttest", type: :instagram, external_id: "https://www.instagram.com/test/"}

    @invalid_contact_attrs %{user_id: "testtesttest", type: :phone, external_id: "955-5490-4146"}
    @invalid_telegram_attrs %{user_id: "testtesttest", type: :instagram, external_id: "https://telegram.org/1111"}
    @invalid_instagram_attrs %{user_id: "testtesttest", type: :instagram, external_id: "https://www.instagr.am/10-tet-10/"}
    @update_contact_attrs %{user_id: "testtesttest", type: :whatsapp, external_id: "+55 99 81234-1234"}

    @valid_attrs %{account: "testtesttest", name: "Jureg", email: "jureg@email.com"}
    @update_attrs %{name: "Jane", email: "jane_doe@email.io", contacts: [@update_contact_attrs, @valid_telegram_attrs, @valid_instagram_attrs]}
    @invalid_attrs %{email: 10, contacts: [@invalid_contact_attrs, @invalid_telegram_attrs, @invalid_instagram_attrs]}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
      |> Repo.preload(:contacts)
    end

    test "collects user by account when one exists" do
      user = insert(:user)
      assert Repo.aggregate(User, :count, :account) == 1
      {:ok, saved_user} = Accounts.get_account_profile(user.account)
      assert saved_user.account == user.account
    end

    test "errors out if no user exists with the given accounts key" do
      assert Repo.aggregate(User, :count, :account) == 0
      {:error, "No user exists with name as their account"} = Accounts.get_account_profile("name")
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      [found_user] = Accounts.list_users()
      assert [found_user |> Repo.preload(:contacts)] == [user]
      users = Accounts.list_users() |> Repo.preload(:contacts)
      assert users == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      found_user = Accounts.get_user!(user.account)
      assert found_user |> Repo.preload(:contacts) == user
      found_user = user.account |> Accounts.get_user!() |> Repo.preload(:contacts)
      assert found_user == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
    end

    test "update_user/2 with valid data updates the user contact" do
      user = user_fixture(%{contacts: [@valid_contact_attrs]})
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user = Accounts.get_user!(user.account)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()

      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.account) end
    end

    test "delete_user/1 deletes the user with contact" do
      user = user_fixture(%{contacts: [@valid_contact_attrs]})
      contact_id = user.contacts |> List.first() |> Map.get(:id)

      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Repo.get_by(Contact, id: contact_id) == nil
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.account) end
    end

    test "change_user/1 returns a user changeset" do
      assert %Ecto.Changeset{} = Accounts.change_user(@valid_attrs)
    end
  end
end
