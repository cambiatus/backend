defmodule Cambiatus.ShopTest do
  use Cambiatus.DataCase

  alias Cambiatus.Shop

  describe "products" do
    alias Cambiatus.Shop.Product

    test "update_product/2 with categories" do
      community = insert(:community)
      product = insert(:product, %{community: community})
      [cat1, cat2] = insert_list(2, :category, %{community: community})

      params = %{product_categories: [%{category_id: cat1.id}, %{category_id: cat2.id}]}

      assert {:ok, %Product{} = product} = Shop.update_product(product, params)
      product = Repo.preload(product, [:categories])
      assert product.categories == Shop.list_categories()
    end
  end

  describe "categories" do
    alias Cambiatus.Shop.Category

    @valid_attrs %{
      name: "some name",
      description: "some description",
      slug: "some slug",
      position: 1
    }
    @update_attrs %{
      description: "some updated description",
      icon_uri: "some updated icon_uri",
      image_uri: "some updated image_uri",
      meta_description: "some updated meta_description",
      meta_keywords: "some updated meta_keywords",
      meta_title: "some updated meta_title",
      name: "some updated name",
      slug: "some updated slug"
    }
    @invalid_attrs %{
      description: nil,
      icon_uri: nil,
      image_uri: nil,
      meta_description: nil,
      meta_keywords: nil,
      meta_title: nil,
      name: nil,
      slug: nil
    }

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Shop.create_category()

      category
    end

    setup do
      {:ok, %{community: insert(:community, has_shop: true)}}
    end

    test "list_categories/0 returns all categories" do
      category = insert(:category)
      assert Shop.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = insert(:category)
      assert Shop.get_category!(category.id) == category
    end

    test "get_category/1 returns the category with given id" do
      category = insert(:category)
      assert Shop.get_category(category.id) == category
    end

    test "create_category/1 with valid data creates a category", %{community: community} do
      params = Map.merge(@valid_attrs, %{community_id: community.symbol})

      assert {:ok, %Category{} = category} = Shop.create_category(params)
      assert category.slug == "some slug"
      assert category.description == "some description"
      assert category.name == "some name"
    end

    test "create_category/1 with an community without shop cannot create categories" do
      community = insert(:community, has_shop: false)
      params = Map.merge(@valid_attrs, %{community_id: community.symbol})

      assert {:error, _} = Shop.create_category(params)
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_category(@invalid_attrs)
    end

    test "create_category/1 with existing subcategory", %{community: community} do
      sub_category = insert(:category, %{community_id: community.symbol})

      params =
        params_for(:category, %{
          community_id: community.symbol,
          categories: [%{id: sub_category.id}]
        })

      assert {:ok, %Category{}} = Shop.create_category(params)
      assert Shop.list_categories() |> length() == 2
    end

    test "update_category/2 with valid data updates the category", %{community: community} do
      category = insert(:category)
      params = Map.merge(@update_attrs, %{community_id: community.symbol})

      assert {:ok, %Category{} = category} = Shop.update_category(category, params)
      assert category.description == "some updated description"
      assert category.icon_uri == "some updated icon_uri"
      assert category.image_uri == "some updated image_uri"
      assert category.meta_description == "some updated meta_description"
      assert category.meta_keywords == "some updated meta_keywords"
      assert category.meta_title == "some updated meta_title"
      assert category.name == "some updated name"
      assert category.slug == "some updated slug"
    end

    test "update_category/2 with invalid data returns error changeset", %{community: community} do
      category = insert(:category)
      params = Map.merge(@invalid_attrs, %{community_id: community.symbol})

      assert {:error, %Ecto.Changeset{}} = Shop.update_category(category, params)
      assert category == Shop.get_category!(category.id)
    end

    test "delete_category/1 deletes the category if the user is an admin" do
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      category = insert(:category, community_id: community.symbol)

      assert {:ok, "Category deleted successfully"} =
               Shop.delete_category(category.id, admin, community.symbol)

      assert_raise Ecto.NoResultsError, fn -> Shop.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset", %{community: community} do
      category = insert(:category, community_id: community.symbol)
      assert %Ecto.Changeset{} = Shop.change_category(category)
    end

    test "Adds subcategories to existing categories", %{community: community} do
      category = insert(:category, %{name: "Tree 🌳", community_id: community.symbol})

      params =
        params_for(:category, %{
          name: "Fruit 🍏",
          community_id: community.symbol,
          parent_id: category.id,
          position: 10
        })

      assert {:ok, %Category{} = sub_category} = Shop.create_category(params)

      category =
        category.id
        |> Shop.get_category!()
        |> Repo.preload([:categories])

      categories = category.categories |> Enum.map(&Repo.preload(&1, [:categories]))

      assert categories == [sub_category]

      another_params =
        params_for(:category, %{
          name: "Another fruit 🍒",
          community_id: community.symbol,
          parent_id: category.id,
          position: 11
        })

      assert {:ok, %Category{} = another_sub_category} = Shop.create_category(another_params)
      category = Repo.preload(Shop.get_category!(category.id), [:categories])

      category =
        category.id
        |> Shop.get_category!()
        |> Repo.preload([:categories])

      categories = category.categories |> Enum.map(&Repo.preload(&1, [:categories]))

      assert categories == [sub_category, another_sub_category]
    end

    test "Add subcategories with position argument", %{community: community} do
      parent = insert(:category)

      {:ok, _one} =
        :category
        |> params_for(%{
          name: "First",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 1
        })
        |> Shop.create_category()

      {:ok, _two} =
        :category
        |> params_for(%{
          name: "Second",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 2
        })
        |> Shop.create_category()

      {:ok, _three} =
        :category
        |> params_for(%{
          name: "Third",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 3
        })
        |> Shop.create_category()

      category = parent.id |> Shop.get_category!() |> Repo.preload(:categories)

      [
        %{name: "First", position: 1},
        %{name: "Second", position: 2},
        %{name: "Third", position: 3}
      ] = category.categories
    end
  end
end
