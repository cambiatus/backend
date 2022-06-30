defmodule CambiatusWeb.Resolvers.ShopTest do
  use Cambiatus.ApiCase

  describe "Shop Resolver" do
    test "create product" do
      user = insert(:user, account: "lucca123")
      community = insert(:community, creator: user.account, has_shop: true)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

      mutation = """
        mutation {
          product(title: "Product title",
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
      community = insert(:community, creator: user.account, has_shop: true)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

      mutation = """
        mutation {
          product(title: "Product title",
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

      community = insert(:community, creator: user.account, has_shop: false)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

      mutation = """
        mutation {
          product(title: "Product title",
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
      community = product.community |> Repo.preload(:subdomain)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

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

    test "update images substitutes old images" do
      user = insert(:user)
      product = insert(:product, %{creator: user})
      community = product.community |> Repo.preload(:subdomain)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

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
      community = product.community |> Repo.preload(:subdomain)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

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

    test "search products" do
      community = insert(:community)

      # Create 3 products, only modifying the name between them
      product_1 = insert(:product, %{title: "Lorem ipsum", community: community})
      product_2 = insert(:product, %{title: "PlAcEhOlDeR tExT", community: community})
      _product_3 = insert(:product, %{title: "never matches", community: community})

      user = insert(:user)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)

      query = fn title ->
        """
        {
          search {
            products(query: "#{title}") {
              title,
              description
            }
          }
        }
        """
      end

      response_1 =
        conn |> post("/api/graph", query: query.(product_1.title)) |> json_response(200)

      response_2 =
        conn |> post("/api/graph", query: query.(product_2.title)) |> json_response(200)

      response_3 =
        conn
        |> post("/api/graph", query: query.("Title not meant to match"))
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => %{
                   "products" => [
                     %{
                       "title" => product_1.title,
                       "description" => product_1.description
                     }
                   ]
                 }
               }
             } == response_1

      assert %{
               "data" => %{
                 "search" => %{
                   "products" => [
                     %{
                       "title" => product_2.title,
                       "description" => product_2.description
                     }
                   ]
                 }
               }
             } == response_2

      assert %{"data" => %{"search" => %{"products" => []}}} = response_3
    end
  end
end
