defmodule BeSpiralWeb.Schema.Resolvers.AccountsTest do
  @moduledoc """
  This module integration tests to for resolvers that work with the accounts context
  """
  use BeSpiral.ApiCase

  alias BeSpiral.{
    Accounts.User
  }

  describe "Accounts Resolver" do
    test "collects a user account given the account name", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      usr = insert(:user)

      variables = %{
        "input" => %{
          "account" => usr.account
        }
      }

      query = """
      query($input: ProfileInput!){ 
        profile(input: $input) {
        account
        avatar
        bio 
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "profile" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == usr.account
    end

    @bio "new bio"
    test "updates a user account details given the account name", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      usr = insert(:user)

      variables = %{
        "input" => %{
          "account" => usr.account,
          "bio" => @bio
        }
      }

      query = """
      mutation($input: ProfileUpdateInput!){
        updateProfile(input: $input) {
          account 
          bio
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "updateProfile" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == usr.account
      refute profile["bio"] == usr.bio
    end
  end
end
