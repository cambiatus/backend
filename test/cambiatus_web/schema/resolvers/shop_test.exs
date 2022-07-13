defmodule CambiatusWeb.Resolvers.ShopTest do
  use Cambiatus.ApiCase

  describe "Product" do
    test "create product" do
      user = insert(:user, account: "lucca123")
      community = insert(:community, creator: user.account, has_shop: true)

      conn = auth_conn(user, community.subdomain.name)

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

      conn = auth_conn(user, community.subdomain.name)

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

      conn = auth_conn(user, community.subdomain.name)

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

    test "owner update existing product" do
      user = insert(:user)
      community = insert(:community)
      product = insert(:product, community: community, creator: user)

      conn = auth_conn(user, community.subdomain.name)

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

      conn = auth_conn(user, community.subdomain.name)

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

    test "can't update product category if category don't exist on the community" do
      user = insert(:user)
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      product = insert(:product, community: community, creator: user)

      another_community = insert(:community)
      invalid_category = insert(:category, community: another_community)

      # conn = build_conn() |> auth_user(user)
      conn = auth_conn(user, community.subdomain.name)

      mutation = """
        mutation {
          product(id: #{product.id}, categories: [#{invalid_category.id}]) {
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
        "data" => %{"product" => nil},
        "errors" => [
          %{
            "details" => %{"product_category" => ["Can't find category with given ID"]},
            "locations" => [%{"column" => 5, "line" => 2}],
            "message" => "Product update failed",
            "path" => ["product"]
          }
        ]
      }

      assert(response == expected_response)
    end

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
      community = insert(:community)
      product = insert(:product, %{creator: user, community: community})

      conn = auth_conn(user, community.subdomain.name)

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
      community = insert(:community)

      product =
        insert(:product, %{creator: user, track_stock: true, units: 10, community: community})

      conn = auth_conn(user, community.subdomain.name)

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
      user = insert(:user)
      community = insert(:community)

      # Create 3 products, only modifying the name between them
      product_1 = insert(:product, %{title: "Lorem ipsum", community: community})
      product_2 = insert(:product, %{title: "PlAcEhOlDeR tExT", community: community})
      _product_3 = insert(:product, %{title: "never matches", community: community})

      conn = auth_conn(user, community.subdomain.name)

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

    test "query products by categories" do
      user = insert(:user)
      community = insert(:community)

      cat_1 = insert(:category, community: community)
      cat_2 = insert(:category, community: community)
      cat_3 = insert(:category, community: community)

      product_1 = insert(:product, creator: user, community: community)
      product_2 = insert(:product, creator: user, community: community)
      product_3 = insert(:product, creator: user, community: community)

      insert(:product_category, product: product_1, category: cat_1)
      insert(:product_category, product: product_1, category: cat_2)
      insert(:product_category, product: product_2, category: cat_1)
      insert(:product_category, product: product_3, category: cat_2)

      conn = auth_conn(user, community.subdomain.name)

      query_1 = """
      query{
        products(filters: {categories_ids: [#{cat_1.id}]}) {
          id,
          title
          }
        }
      """

      query_2 = """
      query{
        products(filters: {categories_ids: [#{cat_1.id}, #{cat_2.id}]}) {
          id,
          title
          }
        }
      """

      query_3 = """
      query{
        products(filters: {categories_ids: [#{cat_3.id}]}) {
          id,
          title
          }
        }
      """

      response1 =
        conn
        |> post("/api/graph", query: query_1)
        |> json_response(200)

      response2 =
        conn
        |> post("/api/graph", query: query_2)
        |> json_response(200)

      response3 =
        conn
        |> post("/api/graph", query: query_3)
        |> json_response(200)

      assert %{
               "data" => %{
                 "products" => [
                   %{"id" => product_1.id, "title" => product_1.title},
                   %{"id" => product_2.id, "title" => product_2.title}
                 ]
               }
             } == response1

      assert %{
               "data" => %{
                 "products" => [
                   %{"id" => product_1.id, "title" => product_1.title},
                   %{"id" => product_2.id, "title" => product_2.title},
                   %{"id" => product_3.id, "title" => product_3.title}
                 ]
               }
             } == response2

      assert %{"data" => %{"products" => []}} == response3
    end
  end

  describe "Category" do
    setup do
      admin = insert(:user)
      community = insert(:community, creator: admin.account)

      conn = auth_conn(admin, community.subdomain.name)

      {:ok, %{conn: conn, community: community}}
    end

    test "create new category", %{conn: conn, community: community} do
      category_params = params_for(:category, community: community)

      mutation = """
        mutation {
          category(name: "#{category_params[:name]}",
                   description: "#{category_params[:description]}",
                   position: 1,
                   slug: "#{category_params[:slug]}") {
            name
            description
            slug
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "category" => %{
                   "name" => category_params[:name],
                   "description" => category_params[:description],
                   "slug" => category_params[:slug]
                 }
               }
             } == response
    end

    test "add existing categories as subcategories to a new category", %{
      conn: conn,
      community: community
    } do
      category_1 = insert(:category, community: community, name: "Art")
      category_2 = insert(:category, community: community, name: "Business")
      category_params = params_for(:category, community: community)

      mutation = """
        mutation {
          category(name: "#{category_params[:name]}",
                   description: "#{category_params[:description]}",
                   slug: "#{category_params[:slug]}",
                   position: 1,
                   categories: [{ id: #{category_1.id}, position: 1 }, { id: #{category_2.id}, position: 2 }]) {
            name
            categories { id }
          }
        }
      """

      res = post(conn, "/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "category" => %{
                   "name" => category_params[:name],
                   "categories" => [
                     %{
                       "id" => category_1.id
                     },
                     %{
                       "id" => category_2.id
                     }
                   ]
                 }
               }
             } == response
    end

    test "add parent category to existing category", %{
      conn: conn,
      community: community
    } do
      category = insert(:category, community: community)
      category_parent = insert(:category, community: community)

      mutation = """
        mutation {
          category(id: #{category_parent.id},
                   categories: [ { id: #{category.id}, position: 1}]) {

            name
            categories { id }
          }
        }
      """

      response = post(conn, "/api/graph", query: mutation) |> json_response(200)

      assert %{
               "data" => %{
                 "category" => %{
                   "name" => category_parent.name,
                   "categories" => [
                     %{
                       "id" => category.id
                     }
                   ]
                 }
               }
             } == response
    end

    test "add parent to new category", %{
      conn: conn,
      community: community
    } do
      parent = insert(:category, community: community)

      mutation = """
        mutation {
          category(name: "New Category",
                   description: "Description",
                   slug: "new-category",
                   position: 1,
                   parentId: #{parent.id}) {
            parent { id }
          }
        }
      """

      response = post(conn, "/api/graph", query: mutation) |> json_response(200)

      assert %{"data" => %{"category" => %{"parent" => %{"id" => parent.id}}}} == response
    end

    test "Deleting a parent category also deletes its children and the products relationship", %{
      conn: conn,
      community: community
    } do
      category_parent = insert(:category, community: community)
      category = insert(:category, community: community, parent: category_parent)

      mutation = """
        mutation {
          deleteCategory(id: #{category_parent.id}) {
            status
            reason
          }
        }
      """

      response = post(conn, "/api/graph", query: mutation) |> json_response(200)

      assert %{
               "data" => %{
                 "deleteCategory" => %{
                   "reason" => "Category deleted successfully",
                   "status" => "success"
                 }
               }
             } == response

      refute Cambiatus.Shop.get_category(category.id)
    end

    test "Updates existing categories with new positioning", %{conn: conn, community: community} do
      parent = insert(:category, community: community)
      leaf_1 = insert(:category, %{community: community, parent_id: parent.id})
      leaf_2 = insert(:category, %{community: community, parent_id: parent.id})

      mutation = """
        mutation {
          category(id: #{parent.id},
                  name: "new name",
                  categories: [{id: #{leaf_1.id}, position: 0}, {id: #{leaf_2.id}, position: 1}]) {
            id
            name
            categories { id position }
          }
        }
      """

      response = post(conn, "/api/graph", query: mutation) |> json_response(200)

      assert %{
               "data" => %{
                 "category" => %{
                   "id" => parent.id,
                   "name" => "new name",
                   "categories" => [
                     %{"id" => leaf_1.id, "position" => 0},
                     %{"id" => leaf_2.id, "position" => 1}
                   ]
                 }
               }
             } == response
    end

    test "Inserts new category with existing categories using position", %{
      conn: conn,
      community: community
    } do
      parent_params = params_for(:category, community: community)
      leaf_1 = insert(:category, community: community)
      leaf_2 = insert(:category, community: community)

      mutation = """
        mutation {
          category(name: "#{parent_params.name}",
                   description: "#{parent_params.description}",
                   slug: "#{parent_params.slug}",
                   position: 0,
                   categories: [
                    { id: #{leaf_1.id}, position: #{leaf_1.position} },
                    { id: #{leaf_2.id}, position: #{leaf_2.position} }]) {
              name
              categories { id position}
            }
        }
      """

      response = post(conn, "/api/graph", query: mutation) |> json_response(200)

      assert %{
               "data" => %{
                 "category" => %{
                   "name" => parent_params.name,
                   "categories" => [
                     %{"id" => leaf_1.id, "position" => leaf_1.position},
                     %{"id" => leaf_2.id, "position" => leaf_2.position}
                   ]
                 }
               }
             } == response
    end
  end
end
