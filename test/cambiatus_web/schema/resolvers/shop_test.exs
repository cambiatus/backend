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

    test "create product fails if not all required fields are filled" do
      user = insert(:user, account: "lucca123")
      conn = build_conn() |> auth_user(user)

      community = insert(:community, creator: user.account, has_shop: true)

      mutation = """
        mutation {
          product(communityId: "#{community.symbol}",
                  title: "Product title",
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
               "data" => %{"product" => nil},
               "errors" => [
                 %{
                   "details" => %{
                     "price" => ["can't be blank"],
                     "description" => ["can't be blank"]
                   },
                   "locations" => _,
                   "message" => _
                 }
               ]
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

    test "owner update existing product" do
      user = insert(:user)
      product = insert(:product, creator: user)

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

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      expected_response = %{
        "data" => %{
          "product" => %{
            "title" => product.title,
            "description" => "Nova descrição"
          }
        }
      }

      assert(response == expected_response)
    end

    test "update product category" do
      user = insert(:user)
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      product = insert(:product, community: community, creator: user)

      [cat_1, cat_2] = insert_list(2, :category, community: community)

      conn = build_conn() |> auth_user(user)

      mutation = """
        mutation {
          product(id: #{product.id}, categories: [#{cat_1.id}, #{cat_2.id}]) {
                    title
                    categories { id }
                  }
        }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      expected_response = %{
        "data" => %{
          "product" => %{
            "categories" => [%{"id" => cat_1.id}, %{"id" => cat_2.id}],
            "title" => product.title
          }
        }
      }

      assert(response == expected_response)
    end

    test "can't update product category if category don't exist on the community"

    test "update_product/2 with an category from another community fails"

    test "admin can update other community members products" do
      user = insert(:user)
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      product = insert(:product, community: community, creator: user)

      conn = build_conn() |> auth_user(admin) |> assign_domain(community.subdomain.name)

      mutation = """
        mutation {
          product(id: #{product.id},
                  description: "one") {
                    title
                    description
                  }
        }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert response == %{
               "data" => %{
                 "product" => %{
                   "title" => product.title,
                   "description" => "one"
                 }
               }
             }
    end

    test "users can't update products they do not own" do
      user = insert(:user)
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      product = insert(:product, community: community, creator: user)

      # Finally we try with someone else, it should fail
      someone = insert(:user)
      conn = build_conn() |> auth_user(someone) |> assign_domain(community.subdomain.name)

      mutation = """
        mutation {
          product(id: #{product.id},
                  description: "one") {
                    title
                    description
                  }
        }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert response == %{
               "data" => %{"product" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 5, "line" => 2}],
                   "message" => "Logged user can't do this action",
                   "path" => ["product"]
                 }
               ]
             }
    end

    test "update images substitutes old images" do
      user = insert(:user)
      product = insert(:product, %{creator: user})

      conn = build_conn() |> auth_user(user)

      mutation = """
      mutation {
        product(id: #{product.id}, images: ["c"]) {
          images { uri }
        }
      }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert %{"data" => %{"product" => %{"images" => [%{"uri" => "c"}]}}} == response
    end

    test "update existing product sending track_stock" do
      user = insert(:user)
      product = insert(:product, %{creator: user, track_stock: true, units: 10})

      conn = build_conn() |> auth_user(user)

      mutation = """
      mutation {
        product(id: #{product.id}, trackStock: false, units: 0) {
          trackStock
          units
        }
      }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert %{"data" => %{"product" => %{"trackStock" => false, "units" => 0}}} == response
    end

    test "delete existing product" do
      user = insert(:user)
      product = insert(:product, %{creator: user})

      conn = build_conn() |> auth_user(user)

      mutation = """
        mutation {
          deleteProduct(id: #{product.id}) {
            status
          }
        }
      """

      response =
        conn
        |> post("/api/graph", query: mutation)
        |> json_response(200)

      assert %{"data" => %{"deleteProduct" => %{"status" => "success"}}} == response
      assert Cambiatus.Shop.get_product(product.id) == nil
    end
  end
end
