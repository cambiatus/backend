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
                  price: 10
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
      assert false
    end
  end
end
