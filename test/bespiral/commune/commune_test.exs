defmodule BeSpiral.CommuneTest do
  use BeSpiral.DataCase

  alias BeSpiral.{
    Commune,
    Commune.Community
  }

  describe "communities" do
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
      subcommunity_price: 0.0
    }
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{symbol: nil}

    test "list_communities/0 returns all communities" do
      community = insert(:community)
      assert Commune.list_communities() == {:ok, [community]}
    end

    test "get_community!/1 returns the community with given symbol" do
      community = insert(:community)
      assert Commune.get_community!(community.symbol) == community
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
      assert community == Commune.get_community!(community.symbol)
    end

    test "delete_community/1 deletes the community" do
      community = insert(:community)
      assert {:ok, %Community{}} = Commune.delete_community(community)
      assert_raise Ecto.NoResultsError, fn -> Commune.get_community!(community.symbol) end
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
          account: another_user,
          community: community,
          invited_by: user
        })

      assert [net] = Commune.list_community_network(community.symbol)
      assert net.id == network.id
    end

    test "list_network/0 returns all network", %{
      community: community,
      user: user,
      another_user: another_user
    } do
      network =
        insert(:network, %{
          account: another_user,
          community: community,
          invited_by: user
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
          account: another_user,
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
            account: another_user,
            community: community,
            invited_by: user
          }
        )
        |> Repo.preload(:community)
        |> Repo.preload(:account)
        |> Repo.preload(:invited_by)

      assert network.account.account == another_user.account
      assert network.community.symbol == community.symbol
      assert network.invited_by.account == user.account
    end

    test "create_network/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commune.create_network(@invalid_attrs)
    end
  end
end
