defmodule CambiatusWeb.Schema.Resolvers.CommuneTest do
  @moduledoc """
  This module holds integration tests for resolvers used when interacting with the
  Commune context, use it to ensure that the the context acts as expected
  """
  use Cambiatus.ApiCase

  alias Cambiatus.{Shop.Product}
  alias Cambiatus.Auth.{Invitation, InvitationId}
  alias Cambiatus.Commune.{Community, Transfer}
  alias Cambiatus.Objectives.{Action, Objective}

  @num 3
  describe "community" do
    test "collects a single transfer" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert(Repo.aggregate(Transfer, :count, :id) == 0)

      transfer = insert(:transfer)

      assert(Repo.aggregate(Transfer, :count, :id) == 1)

      query = """
      query {
        transfer(id: #{transfer.id}) {
          id
          from {
            account
          }
          to {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "transfer" => collected_transfer
        }
      } = json_response(res, 200)

      assert collected_transfer["id"] == transfer.id
      assert collected_transfer["from"]["account"] == transfer.from.account
      assert collected_transfer["to"]["account"] == transfer.to.account
    end

    test "collects a community with its objectives and their actions" do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      comm = insert(:community)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      objectives = insert_list(@num, :objective, %{community: comm})

      Enum.map(objectives, fn obj ->
        insert_list(@num, :action, %{objective: obj})
      end)

      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == @num
      assert Repo.aggregate(Action, :count, :id) == @num * @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert @num == Enum.count(objectives)

      # 3 objectives with 3 actions each
      assert @num * @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all objectives in a community sorted by date" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      cmm = insert(:community)

      _objectives = insert_list(@num, :objective, %{community: cmm})

      assert Repo.aggregate(Objective, :count, :id) == @num

      query = """
      query {
        community(symbol: "#{cmm.symbol}") {
          objectives {
            isCompleted
            completedAt
            createdAt
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert List.first(objectives)["createdAt"] > List.last(objectives)["createdAt"]
    end

    test "collects all communities" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      insert(:community)

      query = """
      query {
        communities {
          symbol
          name
          description
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{"communities" => all_communities}
      } = json_response(res, 200)

      assert Enum.count(all_communities) == 1
    end

    test "collect a single community" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      community = insert(:community)
      community1 = insert(:community)

      query = """
      query {
        community(symbol: "#{community.symbol}") {
          name
        }
      }
      """

      res = conn |> get("/api/graph", query: query)
      %{"data" => %{"community" => found_community}} = json_response(res, 200)

      assert(community.name == found_community["name"])
      assert(community1.name != found_community["name"])
    end

    test "collects all products" do
      assert Repo.aggregate(Product, :count, :id) == 0
      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      user = insert(:user)

      community = insert(:community)

      conn = auth_conn(user, community.subdomain.name)

      insert_list(@num, :product, %{community: community, creator: user})
      insert_list(2, :product, %{community: community})
      %{title: f_title} = insert(:product, %{community: community, inserted_at: latest})

      query = """
      query {
        products {
          id
          title
          description
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "products" => all_sales
        }
      } = json_response(res, 200)

      %{"title" => t} = hd(all_sales)
      assert t == f_title
      assert Enum.count(all_sales) == @num + 3
    end

    test "collects all products from a community" do
      assert Repo.aggregate(Product, :count, :id) == 0

      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      c1 = insert(:community)
      c2 = insert(:community)
      user = insert(:user)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> c1.subdomain.name)

      insert_list(@num, :product, %{units: 0, community: c1})
      insert_list(@num, :product, %{community: c1})

      insert(:network, %{community: c1, user: user})
      insert(:network, %{community: c2, user: user})

      insert(:product, %{community: c2})
      insert(:product, %{creator: user, community: c2})
      %{title: f_title} = insert(:product, %{inserted_at: latest, community: c1})

      query = """
      query {
        products {
          id
          title
          description
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "products" => community_sales
        }
      } = json_response(res, 200)

      assert %{"title" => ^f_title} = hd(community_sales)
      assert Repo.aggregate(Product, :count, :id) == @num * 3
      assert Enum.count(community_sales) == @num * 3 - 2
    end

    test "collects a user's products" do
      assert Repo.aggregate(Product, :count, :id) == 0

      user = insert(:user)

      community = insert(:community)

      conn = auth_conn(user, community.subdomain.name)

      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      %{title: first_title} =
        insert(:product, %{creator: user, inserted_at: latest, community: community})

      insert_list(@num, :product, %{creator: user, community: community})

      variables = %{
        "filters" => %{
          "account" => user.account
        }
      }

      query = """
      query($filters: ProductsFilterInput){
        products(filters: $filters) {
          id
          title
          description
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "products" => user_sales
        }
      } = json_response(res, 200)

      acc = user.account

      assert %{"creator" => %{"account" => ^acc}, "title" => ^first_title} = hd(user_sales)
      # account for the additional sort product
      assert Enum.count(user_sales) == @num + 1
    end

    test "collects a single product" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      product = insert(:product)

      query = """
      query {
        product(id: #{product.id}) {
          id
          title
          description
          insertedAt
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "product" => saved_sale
        }
      } = json_response(res, 200)

      assert Repo.aggregate(Product, :count, :id) == 1
      assert saved_sale["id"] == product.id
    end

    test "collect only sales not deleted" do
      assert Repo.aggregate(Product, :count, :id) == 0

      user = insert(:user)
      community = insert(:community)

      conn = auth_conn(user, community.subdomain.name)

      insert_list(@num, :product, %{community: community, is_deleted: true, creator: user})
      %{title: title} = insert(:product, %{community: community, creator: user})

      query = """
      query {
        products {
          id
          title
          description
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "products" => all_sales
        }
      } = json_response(res, 200)

      # total of 4 sales, being:
      # - 3 deleted
      # - 1 not deleted
      assert Enum.count(all_sales) == 1
      assert %{"title" => ^title} = hd(all_sales)
    end

    test "collects a user's transfers" do
      assert Repo.aggregate(Transfer, :count, :id) == 0
      user = insert(:user)

      conn = build_conn() |> auth_user(user)

      user1 = insert(:user)
      insert_list(@num, :transfer, %{from: user1})
      insert_list(@num, :transfer, %{from: user})
      insert_list(@num, :transfer, %{to: user})

      fetch = 3

      variables = %{
        "account" => user.account
      }

      query = """
      query($account: String!) {
        user(account: $account) {
          transfers(first: #{fetch}) {
            count
            edges {
              node {
                from_id
                to_id
                amount
                memo
              }
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "count" => total_count
            }
          }
        }
      } = json_response(res, 200)

      assert total_count == @num * 2
      assert Repo.aggregate(Transfer, :count, :id) == @num * 3
    end

    test "collects a community s features" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      community = insert(:community)

      variables = %{
        "symbol" => community.symbol
      }

      query = """
      query($symbol: String!) {
        community(symbol: $symbol) {
          has_objectives,
          has_shop,
          has_kyc
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "community" => %{
            "has_objectives" => actions,
            "has_shop" => shop,
            "has_kyc" => kyc
          }
        }
      } = json_response(res, 200)

      assert actions == true
      assert shop == true
      assert kyc == false
    end

    test "collects a community's transfers" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert Repo.aggregate(Transfer, :count, :id) == 0
      community = insert(:community)
      comm = insert(:community)

      insert_list(@num, :transfer, %{community: comm})
      insert_list(@num, :transfer, %{community: community})

      fetch = 2

      variables = %{
        "symbol" => community.symbol
      }

      query = """
      query($symbol: String!) {
        community(symbol: $symbol) {
          transfers(first: #{fetch}) {
            count
            edges {
              node {
                from_id
                to_id
                amount
                memo
              }
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "community" => %{
            "transfers" => %{
              "count" => total_count
            }
          }
        }
      } = json_response(res, 200)

      assert total_count == @num
      assert Repo.aggregate(Transfer, :count, :id) == @num * 2
    end

    test "collect a single invitation", %{conn: conn} do
      assert(Repo.aggregate(Invitation, :count, :id) == 0)
      invite = insert(:invitation)
      invite_id = InvitationId.encode(invite.id)

      query = """
        query {
          invite(id: "#{invite_id}") {
            creator {
              account
            }
            communityPreview {
              symbol
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query)
      %{"data" => %{"invite" => found_invite}} = json_response(res, 200)

      assert(invite.creator_id == found_invite["creator"]["account"])
      assert(invite.community_id == found_invite["communityPreview"]["symbol"])
    end

    test "updates community has_news flag" do
      user = insert(:user)

      community =
        insert(:community, %{creator: user.account, has_news: false, symbol: "symbol-0"})

      conn = auth_conn(user, community.subdomain.name)

      query = """
      mutation {
        community(input: {hasNews: true}){
          symbol
          hasNews
        }
      }
      """

      res = post(conn, "/api/graph", query: query)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "community" => %{
                   "hasNews" => true,
                   "symbol" => "symbol-0"
                 }
               }
             } = response

      assert Repo.get!(Community, community.symbol).has_news == true
    end

    test "updates highlighted news of community" do
      user = insert(:user)

      community =
        insert(:community, %{
          creator: user.account,
          has_news: true,
          symbol: "symbol-0",
          highlighted_news: nil
        })

      news_id = insert(:news, %{community: community, user: user}).id

      conn = auth_conn(user, community.subdomain.name)

      query = """
      mutation {
        highlightedNews(newsID: #{news_id}){
          symbol
          highlighted_news {
            id
          }
        }
      }
      """

      res = post(conn, "/api/graph", query: query)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "highlightedNews" => %{
                   "symbol" => "symbol-0",
                   "highlighted_news" => %{
                     "id" => ^news_id
                   }
                 }
               }
             } = response

      assert Repo.get!(Community, community.symbol).highlighted_news_id == news_id
    end

    test "removes highlighted news of community" do
      user = insert(:user)

      community =
        insert(:community, %{
          creator: user.account,
          has_news: true,
          symbol: "symbol-0"
        })

      news = insert(:news, %{community: community, user: user})
      Community.changeset(community, %{highlighted_news_id: news.id}) |> Repo.update!()

      conn = auth_conn(user, community.subdomain.name)

      query = """
      mutation {
        highlightedNews{
          symbol
          highlighted_news {
            id
          }
        }
      }
      """

      assert Repo.get!(Community, community.symbol).highlighted_news_id == news.id

      res = post(conn, "/api/graph", query: query)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "highlightedNews" => %{
                   "symbol" => "symbol-0",
                   "highlighted_news" => nil
                 }
               }
             } = response

      assert Repo.get!(Community, community.symbol).highlighted_news_id == nil
    end
  end
end
