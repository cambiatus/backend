defmodule CambiatusWeb.Resolvers.SocialTest do
  use Cambiatus.ApiCase

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

    test "mark news as read creating a news_receipt for the user in the news" do
      user = insert(:user)
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
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "read" => %{"inserted_at" => _, "reactions" => [], "updated_at" => _}
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
        reactToNews(news_id: #{news.id}, reactions: [":joy:", ":smile:"]){
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
                 "reactions" => [":joy:", ":smile:"],
                 "updated_at" => _
               }
             }
           } = response
  end

  test "get news by id" do
    news = insert(:news)
    user = insert(:user)
    conn = build_conn() |> auth_user(user)

    query = """
    query{
      news(newsID: #{news.id}){
        title
        description
        reactions
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
                 "reactions" => "{}"
               }
             }
           } = response
  end
end
