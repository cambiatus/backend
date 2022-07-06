defmodule Cambiatus.ShopTest do
  use Cambiatus.DataCase

  alias Cambiatus.Shop
  alias Cambiatus.Shop.Category

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
          position: 2,
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

    test "delete_category/1 deletes a root category and its childs" do
      admin = insert(:user)
      community = insert(:community, creator: admin.account)
      root = insert(:category, community: community)
      child = insert(:category, community: community, parent_id: root.id)
      grandchild = insert(:category, community: community, parent_id: child.id)

      assert {:ok, "Category deleted successfully"} =
               Shop.delete_category(child.id, admin, community.symbol)

      assert %Category{} = Shop.get_category(root.id)
      assert_raise Ecto.NoResultsError, fn -> Shop.get_category!(child.id) end
      assert_raise Ecto.NoResultsError, fn -> Shop.get_category!(grandchild.id) end
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
          position: 2
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
          position: 1
        })

      assert {:ok, %Category{} = another_sub_category} = Shop.create_category(another_params)
      category = Repo.preload(Shop.get_category!(category.id), [:categories])

      category =
        category.id
        |> Shop.get_category!()
        |> Repo.preload([:categories])

      categories =
        category.categories
        |> Enum.map(&Repo.preload(&1, [:categories]))
        |> Enum.sort(fn a, b -> a.position < b.position end)

      assert categories == [another_sub_category, sub_category]
    end

    test "Add subcategories with position argument", %{community: community} do
      parent = insert(:category)

      {:ok, _one} =
        :category
        |> params_for(%{
          name: "First",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 0
        })
        |> Shop.create_category()

      {:ok, _two} =
        :category
        |> params_for(%{
          name: "Second",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 1
        })
        |> Shop.create_category()

      {:ok, _three} =
        :category
        |> params_for(%{
          name: "Third",
          community_id: community.symbol,
          parent_id: parent.id,
          position: 2
        })
        |> Shop.create_category()

      category = parent.id |> Shop.get_category!() |> Repo.preload(:categories)

      [
        %{name: "First", position: 0},
        %{name: "Second", position: 1},
        %{name: "Third", position: 2}
      ] = category.categories
    end
  end

  describe "categories positioning" do
    setup do
      {:ok, %{community: insert(:community, has_shop: true)}}
    end

    test "root position validations: can't be negative", %{community: community} do
      params = params_for(:category, %{community: community, position: -1})
      assert {:error, details} = Shop.create_category(params)
      assert %{position: ["position cant be negative"]} == errors_on(details)
    end

    test "root position validations: can't create new categories with position > last position +1",
         %{community: community} do
      # Creates random number of root categories
      n = Enum.random(3..20)
      root_categories = insert_list(n, :category, community: community)

      # Add more, but this time they belong to a random category
      _other_categories =
        insert_list(5, :category,
          community: community,
          parent_id: Enum.random(root_categories) |> Map.get(:id)
        )

      # Try to insert a position, but on a position that doesn't exist today
      params = params_for(:category, %{community: community, position: n + 2, parent_id: nil})

      assert {:error, details} = Shop.create_category(params)

      assert %{position: ["for new categories, position must be smaller or equal than #{n + 1}"]} ==
               errors_on(details)

      # Modify to a valid position
      params = %{params | position: n + 1}
      assert {:ok, _} = Shop.create_category(params)
    end

    test "root position validations: when updating, position must be a value <= last position", %{
      community: community
    } do
      # Creates random number of root categories
      n = Enum.random(3..20)
      root_categories = insert_list(n, :category, community: community)

      # Add more, but this time they belong to a random category
      _other_categories =
        insert_list(5, :category,
          community: community,
          parent_id: Enum.random(root_categories) |> Map.get(:id)
        )

      # Try to update a position, but on a position that doesn't exist today
      category = Enum.random(root_categories)
      assert {:error, details} = Shop.update_category(category, %{position: n + 1})

      assert %{position: ["for existing categories, position must be smaller or equal than #{n}"]} ==
               errors_on(details)

      assert {:ok, _} = Shop.update_category(category, %{position: n - 1})
    end

    test "Insert new root category reorders all other root categories"

    test "Update root category with new positioning reorders all other root categories", %{
      community: community
    } do
      # Create random number of root categories
      # TODO: n = Enum.random(3..20)
      n = Enum.random(3..5)
      root_categories = insert_list(n, :category, community: community)

      # Create random number of child categories, to make sure they don't affect the ordering
      _other_categories =
        insert_list(Enum.random(5..10), :category,
          community: community,
          # Random parent
          parent_id: root_categories |> Enum.random() |> Map.get(:id)
        )

      # Change a single category position to the end
      # and check if it changed position for every other root category
      category = root_categories |> Enum.random()

      {:ok, _updated_category} =
        Shop.update_category(category, %{position: Enum.random(0..(n - 1))})

      # TODO: remove this
      updated_root_categories =
        Category
        |> Category.from_community(community.symbol)
        |> Category.roots()
        |> Repo.all()

      assert Enum.map(root_categories, &Map.take(&1, [:id, :position])) ==
               Enum.map(updated_root_categories, &Map.take(&1, [:id, :position]))
    end

    test "new position > old position"
    test "new position < old position"
    test "new position beginning of list"
    test "new position end of list"
  end
end
