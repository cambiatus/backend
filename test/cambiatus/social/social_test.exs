defmodule Cambiatus.SocialTest do
  use Cambiatus.DataCase

  alias Cambiatus.Social
  alias Cambiatus.Social.News

  describe "news" do
    setup :valid_community_and_user

    @valid_attrs %{
      title: "Some title",
      description: "Some description"
    }

    @valid_attrs_with_scheduling %{
      title: "Some title",
      description: "Some description",
      scheduling: DateTime.utc_now() |> DateTime.add(3600, :second)
    }

    test "create a valid news with scheduling", %{user: user, community: community} do
      params =
        Map.merge(@valid_attrs_with_scheduling, %{
          user_id: user.account,
          community_id: community.symbol
        })

      assert {:ok, %News{}} = Social.create_news(params)
    end

    test "returns error if user is invalid", %{community: community} do
      params = Map.merge(@valid_attrs, %{community_id: community.symbol, user_id: 12_738})

      assert {:error, changeset} = Social.create_news(params)

      refute(changeset.valid?)
    end

    test "returns error if community is invalid", %{user: user} do
      params = Map.merge(@valid_attrs, %{user_id: user.account, community_id: "0,TES"})

      assert {:error, changeset} = Social.create_news(params)

      refute(changeset.valid?)
    end

    test "returns error if the user is not the community admin", %{
      community: community,
      another_user: another_user
    } do
      params =
        Map.merge(@valid_attrs, %{community_id: community.symbol, user_id: another_user.account})

      assert {:error, changeset} = Social.create_news(params)

      assert(
        Map.get(changeset, :errors) == [
          user_id: {"is not admin", []}
        ]
      )
    end

    test "returns error when scheduling is earlier than now", %{user: user, community: community} do
      params =
        Map.merge(@valid_attrs, %{
          community_id: community.symbol,
          user_id: user.account,
          scheduling: DateTime.utc_now() |> DateTime.add(-10, :second)
        })

      assert {:error, changeset} = Social.create_news(params)

      assert(
        Map.get(changeset, :errors) == [
          scheduling: {"is invalid", []}
        ]
      )
    end
  end
end
