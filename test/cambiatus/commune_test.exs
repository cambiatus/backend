defmodule Cambiatus.CommuneTest do
  use Cambiatus.DataCase

  alias Cambiatus.Commune
  alias Cambiatus.Commune.Community

  describe "commune" do
    @valid_attrs %{
      symbol: "TES",
      issuer: "testtesttest",
      creator: "testtesttest",
      name: "sample community",
      description: "desc TES",
      supply: 10.0,
      max_supply: 100.0,
      min_balance: -100.0,
      inviter_reward: 0.0,
      invited_reward: 0.0,
      allow_subcommunity: true,
      subcommunity_price: 0.0,
      subdomain: %{name: "test.cambiatus.io"}
    }
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{symbol: nil}

    test "list_communities/0 returns all communities" do
      community = insert(:community)
      {:ok, [found_community]} = Commune.list_communities()
      assert found_community.symbol == community.symbol
      assert found_community.description == community.description
    end

    test "get_community!/1 returns the community with given symbol" do
      community = insert(:community)
      found_community = Commune.get_community!(community.symbol)
      assert found_community.symbol == community.symbol
      assert found_community.description == community.description
    end

    test "create_community/1 with valid data creates a community" do
      assert {:ok, %Community{} = community} = Commune.create_community(@valid_attrs)
      assert community.symbol == "TES"
    end

    test "create_community/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commune.create_community(@invalid_attrs)
    end

    test "update_community/2 with valid data updates the community" do
      community = insert(:community)
      assert {:ok, %Community{} = community} = Commune.update_community(community, @update_attrs)
      assert community.name == "some updated name"
    end

    test "update_community/2 with invalid data returns error changeset" do
      community = insert(:community)
      assert {:error, %Ecto.Changeset{}} = Commune.update_community(community, @invalid_attrs)
      assert community.symbol == Commune.get_community!(community.symbol).symbol
    end

    test "delete_community/1 deletes the community" do
      community = insert(:community)
      assert {:ok, %Community{}} = Commune.delete_community(community)
      assert_raise Ecto.NoResultsError, fn -> Commune.get_community!(community.symbol) end
    end

    test "set_highlighted_news/3 sets the news as highlighted in community without current_user" do
      community = insert(:community)
      news = insert(:news, community: community)

      assert community.highlighted_news_id == nil

      assert {:ok, %Community{} = community} =
               Commune.set_highlighted_news(community.symbol, news.id)

      assert community.highlighted_news_id == news.id
    end

    test "set_highlighted_news/3 sets the news as highlighted in community with current_user" do
      user = insert(:user)

      community =
        insert(:community, creator: user.account, has_news: true, highlighted_news_id: nil)

      news = insert(:news, user: user, community: community)

      assert community.highlighted_news_id == nil

      assert {:ok, %Community{} = community} =
               Commune.set_highlighted_news(community.symbol, news.id, user)

      assert community.highlighted_news_id == news.id
    end

    test "set_highlighted_news/3 sets the news as highlighted in community with invalid current_user" do
      another_user = insert(:user)
      user = insert(:user)

      community =
        insert(:community, creator: user.account, has_news: true, highlighted_news_id: nil)

      news = insert(:news, user: user, community: community)

      assert {:error, "Unauthorized"} =
               Commune.set_highlighted_news(community.symbol, news.id, another_user)

      assert community.highlighted_news_id == nil
    end

    test "set_highlighted_news/3 sets the news as highlighted in community with invalid community" do
      user = insert(:user)

      community =
        insert(:community,
          creator: user.account,
          has_news: true,
          highlighted_news_id: nil,
          symbol: "symbol-0"
        )

      news = insert(:news, user: user, community: community)

      assert {:error, "No community exists with the symbol: invalid-1"} =
               Commune.set_highlighted_news("invalid-1", news.id, user)
    end

    test "set_highlighted_news/3 sets the news as highlighted in community with news from another community" do
      community =
        insert(:community,
          has_news: true,
          highlighted_news_id: nil
        )

      another_community = insert(:community)

      news = insert(:news, community: another_community)

      assert {:error, "News does not belong to community"} =
               Commune.set_highlighted_news(community.symbol, news.id)
    end

    test "set_has_news/3 sets community has_news flag" do
      user = insert(:user)
      community = insert(:community, creator: user.account, has_news: false)

      response = Commune.update_community(community.symbol, user, %{has_news: true})

      assert {:ok, %Community{has_news: true}} = response
      assert Repo.get!(Community, community.symbol).has_news == true
    end

    test "set_has_news/3 returns unauthorized if user is not admin" do
      user = insert(:user)
      community = insert(:community, has_news: false)

      response = Commune.update_community(community.symbol, user, %{has_news: true})

      assert {:error, "Unauthorized"} == response
    end

    test "set_has_news/3 returns error if community is not found" do
      user = insert(:user)

      response = Commune.update_community("any_community", user, %{has_news: true})

      assert {:error, "No community exists with the symbol: any_community"} == response
    end
  end

  describe "network" do
    setup :valid_community_and_user

    @invalid_attrs %{account: nil, community: nil, invited_by: nil}

    test "list_community_network/1 returns community network", %{
      community: community,
      user: user,
      another_user: another_user
    } do
      network =
        insert(:network, %{
          user: another_user,
          community: community,
          invited_by: user
        })

      assert [net] = Commune.list_community_network(community.symbol)
      assert net.id == network.id
    end

    test "list_network/0 returns all network", %{
      community: community,
      another_user: another_user
    } do
      network =
        insert(:network, %{
          user: another_user,
          community: community
        })

      assert [net] = Commune.list_network()
      assert net.id == network.id
    end

    test "get_network!/1 returns the network with given id", %{
      community: community,
      user: user,
      another_user: another_user
    } do
      network =
        insert(:network, %{
          user: another_user,
          community: community,
          invited_by: user
        })

      assert net = Commune.get_network!(network.id)
      assert net.id == network.id
    end

    test "create_network/1 with valid data creates a network", %{
      community: community,
      user: user,
      another_user: another_user
    } do
      network =
        insert(
          :network,
          %{
            user: another_user,
            community: community,
            invited_by: user
          }
        )
        |> Repo.preload(:community)
        |> Repo.preload(:user)
        |> Repo.preload(:invited_by)

      assert network.user.account == another_user.account
      assert network.community.symbol == community.symbol
      assert network.invited_by.account == user.account
    end

    test "create_network/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commune.create_network(@invalid_attrs)
    end
  end
end
