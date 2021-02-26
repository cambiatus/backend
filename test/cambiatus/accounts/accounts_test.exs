defmodule Cambiatus.AccountsTest do
  use Cambiatus.DataCase

  alias Cambiatus.Accounts

  describe "users" do
    alias Cambiatus.Accounts.User

    @valid_attrs %{account: "testtesttest", name: "Jureg", email: "jureg@email.com"}
    @update_attrs %{}
    @invalid_attrs %{email: 10}

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
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      found_user = Accounts.get_user!(user.account)
      assert found_user |> Repo.preload(:contacts) == user
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

    test "change_user/1 returns a user changeset" do
      assert %Ecto.Changeset{} = Accounts.change_user(@valid_attrs)
    end
  end
end
