defmodule CambiatusWeb.Resolvers.ShopTest do
  use Cambiatus.ApiCase

  describe "Shop Resolver" do
    test "create product" do
      user = insert(:user, account: "lucca123")
      conn = build_conn() |> auth_user(user)

      community = insert(:community, creator: user.account, has_shop: true)

      mutation = """
        mutation {
          product(communityId: "#{community.symbol}",
                  title: "Product title",
                  description: "Product description",
                  price: 10.0000,
                  images: [],
                  trackStock: false) {
            title
            description
            creator {
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
                 "product" => %{
                   "title" => "Product title",
                   "description" => "Product description",
                   "creator" => %{"account" => "lucca123"},
                   "inserted_at" => _
                 }
               }
             } = response
    end

    test "create product fails if shop is not enabled" do
      user = insert(:user, account: "lucca123")
      conn = build_conn() |> auth_user(user)

      community = insert(:community, creator: user.account, has_shop: false)

      mutation = """
        mutation {
          product(communityId: "#{community.symbol}",
                  title: "Product title",
                  description: "Product description",
                  price: 10.0000,
                  images: [],
                  trackStock: false){
            title
            description
            creator {
              account
            }
            inserted_at
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{"product" => nil},
               "errors" => [
                 %{
                   "details" => %{"community_id" => ["shop is not enabled"]},
                   "locations" => _,
                   "message" => _
                 }
               ]
             } = response
    end

    test "update existing product" do
      user = insert(:user)
      product = insert(:product)

      conn = build_conn() |> auth_user(user)

      mutation = """
        mutation {
          product(id: #{product.id},
                  description: "Nova descrição") {
                    title
                    description
                  }
        }
      """

      _response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert %{
        "data" => %{
          "product" => %{
            "title" => product.title,
            "description" => "Nova descrição"
          }
        }
      }
    end
  end
end
