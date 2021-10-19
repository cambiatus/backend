defmodule Cambiatus.SocialTest do
  use Cambiatus.DataCase

  alias Cambiatus.Social
  alias Cambiatus.Social.{News, NewsReceipt, NewsVersion}

  describe "create_news/1" do
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

    test "create a valid news with scheduling", %{user: user} do
      community = insert(:community, has_news: true, creator: user.account)

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
      user: user,
      another_user: another_user
    } do
      community = insert(:community, has_news: true, creator: user.account)

      params =
        Map.merge(@valid_attrs, %{community_id: community.symbol, user_id: another_user.account})

      assert {:error, changeset} = Social.create_news(params)

      assert(
        Map.get(changeset, :errors) == [
          user_id: {"is not admin", []}
        ]
      )
    end

    test "returns error when scheduling is earlier than now", %{user: user} do
      community = insert(:community, has_news: true, creator: user.account)

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

    test "returns error when community has_news is not enabled", %{
      user: user,
      community: community
    } do
      params =
        Map.merge(@valid_attrs_with_scheduling, %{
          user_id: user.account,
          community_id: community.symbol
        })

      assert community.has_news == false
      assert {:error, changeset} = Social.create_news(params)

      assert(
        Map.get(changeset, :errors) == [
          community_id: {"news is not enabled", []}
        ]
      )
    end
  end

  describe "upsert_news_receipt/3" do
    test "when all params are correct, creates a news receipt successfully" do
      user = insert(:user)
      news = insert(:news)
      reactions = [":laugh:", ":joy:"]

      assert {:ok, %NewsReceipt{} = receipt} =
               Social.upsert_news_receipt(news.id, user.account, reactions)

      assert receipt.news_id == news.id
      assert receipt.user_id == user.account
      assert receipt.reactions == [":laugh:", ":joy:"]
    end

    test "when all has no reactions in params, creates a news receipt with empty reactions" do
      user = insert(:user)
      news = insert(:news)

      assert {:ok, %NewsReceipt{} = receipt} = Social.upsert_news_receipt(news.id, user.account)
      assert receipt.news_id == news.id
      assert receipt.user_id == user.account
      assert receipt.reactions == []
    end

    test "when there is a receipt with same user and news, updates the reactions" do
      news_receipt = insert(:news_receipt, reactions: [":joy:"])
      new_reactions = [":joy:", ":smile:", ":laugh:"]

      assert {:ok, %NewsReceipt{} = receipt} =
               Social.upsert_news_receipt(
                 news_receipt.news_id,
                 news_receipt.user_id,
                 new_reactions
               )

      assert receipt.news_id == news_receipt.news_id
      assert receipt.user_id == news_receipt.user_id
      assert receipt.reactions == [":joy:", ":smile:", ":laugh:"]
    end
  end

  describe "get_news_reactions/1" do
    test "returns a list of reactions" do
      news = insert(:news)

      insert(:news_receipt, news: news, reactions: ["a", "b"])
      insert(:news_receipt, news: news, reactions: ["a", "c"])
      insert(:news_receipt, news: news, reactions: ["b", "c"])
      insert(:news_receipt, news: news, reactions: ["b"])
      insert(:news_receipt, news: news, reactions: ["b", "d"])

      response = Social.get_news_reactions(news.id)

      assert response == [
               %{reaction: "a", count: 2},
               %{reaction: "b", count: 4},
               %{reaction: "c", count: 2},
               %{reaction: "d", count: 1}
             ]
    end

    test "returns an empty list if news has no reactions" do
      news = insert(:news)

      response = Social.get_news_reactions(news.id)

      assert response == []
    end

    test "returns an empty list if news does not exist" do
      response = Social.get_news_reactions(1234)

      assert response == []
    end

    test "returns only reactions from given news" do
      news = insert(:news)
      news2 = insert(:news)

      insert(:news_receipt, news: news, reactions: ["a", "b"])
      insert(:news_receipt, news: news, reactions: ["b", "c"])
      insert(:news_receipt, news: news2, reactions: ["a", "c"])

      response = Social.get_news_reactions(news.id)

      assert response == [
               %{reaction: "a", count: 1},
               %{reaction: "b", count: 2},
               %{reaction: "c", count: 1}
             ]
    end
  end

  describe "update_news_with_history/1" do
    test "when input is valid news, updates the news and creates a news_version" do
      user = insert(:user)
      community = insert(:community, has_news: true, creator: user.account)

      news =
        insert(:news, title: "Title", description: "Description", community: community, user: user)

      news_params = %{
        title: "Updated title",
        description: "Updated description"
      }

      {:ok, _} = Social.update_news_with_history(news, news_params)

      updated_news = Repo.get(News, news.id)
      news_version = Repo.get_by(NewsVersion, news_id: news.id)

      assert updated_news.title == "Updated title"
      assert updated_news.description == "Updated description"
      assert news_version.title == "Title"
      assert news_version.description == "Description"
    end
  end

  describe "get_news_versions/1" do
    test "returns all versions from news" do
      news = insert(:news)

      insert(:news_version, news: news)
      insert(:news_version, news: news)
      insert(:news_version)

      response = Social.get_news_versions(news.id)

      assert Enum.count(response) == 2
    end

    test "returns an empty array when there are no versions for the news" do
      response = Social.get_news_versions(1234)

      assert response == []
    end
  end
end
