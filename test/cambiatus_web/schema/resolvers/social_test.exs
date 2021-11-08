defmodule CambiatusWeb.Resolvers.SocialTest do
  use Cambiatus.ApiCase

  alias Cambiatus.Social.NewsVersion

  describe "Social Resolver" do
    test "create news" do
      user = insert(:user, account: "test1234")
      conn = build_conn() |> auth_user(user)

      community = insert(:community, creator: user.account, has_news: true)

      mutation = """
        mutation {
          news(communityId: "#{community.symbol}", title: "News title", description: "News description"){
            title
            description
            user {
              account
            }
            inserted_at
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "news" => %{
                   "title" => "News title",
                   "description" => "News description",
                   "user" => %{"account" => "test1234"},
                   "inserted_at" => _
                 }
               }
             } = response
    end

    test "update news should create news version" do
      community_creator = insert(:user, account: "test1234")
      community = insert(:community, creator: community_creator.account, has_news: true)

      news =
        insert(:news,
          community: community,
          user: community_creator,
          title: "Title",
          description: "Description"
        )

      conn = build_conn() |> auth_user(community_creator)

      mutation = """
        mutation {
          updateNews(id: #{news.id}, title: "New title", description: "New description"){
            title
            description
            user {
              account
            }
            inserted_at
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "updateNews" => %{
                   "title" => "New title",
                   "description" => "New description",
                   "user" => %{"account" => "test1234"},
                   "inserted_at" => _
                 }
               }
             } = response

      assert %{title: "Title", description: "Description"} =
               Repo.get_by(NewsVersion, news_id: news.id)
    end

    test "mark news as read creating a news_receipt for the user in the news" do
      user = insert(:user, account: "johndoe")
      conn = build_conn() |> auth_user(user)

      community_creator = insert(:user)
      community = insert(:community, creator: community_creator.account, has_news: true)
      news = insert(:news, community: community, user: community_creator)

      mutation = """
        mutation {
          read(news_id: #{news.id}){
            reactions
            inserted_at
            updated_at
            user {
              account
            }
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "read" => %{
                   "inserted_at" => _,
                   "reactions" => [],
                   "updated_at" => _,
                   "user" => %{"account" => "johndoe"}
                 }
               }
             } = response
    end
  end

  test "updates users reactions to news" do
    user = insert(:user)
    conn = build_conn() |> auth_user(user)

    community_creator = insert(:user)
    community = insert(:community, creator: community_creator.account, has_news: true)
    news = insert(:news, community: community, user: community_creator)

    mutation = """
      mutation {
        reactToNews(news_id: #{news.id}, reactions: [ROCKET, PARTY_POPPER]){
          reactions
          inserted_at
          updated_at
        }
      }
    """

    res = post(conn, "/api/graph", query: mutation)

    response = json_response(res, 200)

    assert %{
             "data" => %{
               "reactToNews" => %{
                 "inserted_at" => _,
                 "reactions" => ["ROCKET", "PARTY_POPPER"],
                 "updated_at" => _
               }
             }
           } = response
  end

  test "get news by id" do
    news = insert(:news)
    user = insert(:user)
    insert(:network, community: news.community, account: user)
    conn = build_conn() |> auth_user(user)

    query = """
    query{
      news(newsID: #{news.id}){
        title
        description
        reactions {
          reaction
          count
        }
      }
    }
    """

    res = post(conn, "/api/graph", query: query)
    response = json_response(res, 200)

    assert %{
             "data" => %{
               "news" => %{
                 "description" => "News description",
                 "title" => "News title",
                 "reactions" => []
               }
             }
           } = response
  end

  test "get news by id with reactions, versions and user receipt" do
    user = insert(:user)
    community = insert(:community, creator: user.account)
    news = insert(:news, user: user, community: community)
    insert(:news_receipt, news: news, user: user, reactions: [:rocket])
    insert(:news_receipt, news: news, reactions: [:red_heart, :thumbs_up])
    insert(:news_receipt, news: news, reactions: [:thumbs_up])
    insert(:network, community: community, account: user)
    insert(:news_version, news: news, title: "Hello World")
    insert(:news_version, news: news, title: "Hi World")
    conn = build_conn() |> auth_user(user)

    query = """
    query{
      news(newsID: #{news.id}){
        title
        description
        reactions {
          reaction
          count
        }
        versions {
          title
        }
        receipt {
          reactions
        }
      }
    }
    """

    res = post(conn, "/api/graph", query: query)
    response = json_response(res, 200)

    assert %{
             "data" => %{
               "news" => %{
                 "description" => "News description",
                 "title" => "News title",
                 "reactions" => [
                   %{"count" => 1, "reaction" => "RED_HEART"},
                   %{"count" => 1, "reaction" => "ROCKET"},
                   %{"count" => 2, "reaction" => "THUMBS_UP"}
                 ],
                 "versions" => [
                   %{"title" => "Hello World"},
                   %{"title" => "Hi World"}
                 ],
                 "receipt" => %{
                   "reactions" => ["ROCKET"]
                 }
               }
             }
           } = response
  end

  test "get news by id gets nil news_receipt if user has not read the news yet" do
    user = insert(:user)
    another_user = insert(:user)
    news = insert(:news)
    insert(:network, community: news.community, account: user)
    insert(:news_receipt, news: news, user: another_user)

    conn = build_conn() |> auth_user(user)

    query = """
    query{
      news(newsID: #{news.id}){
        receipt {
          reactions
        }
      }
    }
    """

    res = post(conn, "/api/graph", query: query)
    response = json_response(res, 200)

    assert %{
             "data" => %{
               "news" => %{
                 "receipt" => nil
               }
             }
           } = response
  end

  test "get news by id returns error if user is not from community" do
    news = insert(:news)
    user = insert(:user)
    conn = build_conn() |> auth_user(user)

    query = """
    query{
      news(newsID: #{news.id}){
        title
        description
        reactions {
          reaction
          count
        }
      }
    }
    """

    res = post(conn, "/api/graph", query: query)
    response = json_response(res, 200)

    assert %{
             "data" => %{"news" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 3, "line" => 2}],
                 "message" => "User unauthorized",
                 "path" => ["news"]
               }
             ]
           } == response
  end
end
