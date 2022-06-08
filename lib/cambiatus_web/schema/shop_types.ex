defmodule CambiatusWeb.Schema.ShopTypes do
  @moduledoc """
  Holds all Absinthe Schema Objects, inputs, mutations and queries related to the Shop
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Shop
  alias CambiatusWeb.Schema.Middleware

  @desc "Shop queries"
  object(:shop_queries) do
    @desc "[Auth required] Products in a community"
    field(:products, non_null(list_of(non_null(:product)))) do
      arg(:community_id, non_null(:string))
      arg(:filters, :products_filter_input)

      middleware(Middleware.Authenticate)
      resolve(&Shop.get_products/3)
    end

    @desc "[Auth required] Gets a single product"
    field(:product, :product) do
      arg(:id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Shop.get_product/3)
    end

    @desc "Public product query, mainly used to preview a sale"
    field(:product_preview, non_null(:product_preview)) do
      arg(:id, non_null(:integer))

      resolve(&Shop.get_product/3)
    end
  end

  @desc "Shop mutations"
  object(:shop_mutations) do
    @desc "[Auth required] Upserts a product"
    field :product, :product do
      arg(:id, :integer)
      arg(:community_id, :string)
      arg(:title, :string)
      arg(:description, :string)
      arg(:price, :float)
      arg(:images, list_of(non_null(:string)))
      arg(:track_stock, :boolean)
      arg(:units, :integer)

      arg(:categories, list_of(non_null(:integer)),
        description: "List of categories ID you want to relate to this product"
      )

      middleware(Middleware.Authenticate)
      resolve(&Shop.upsert_product/3)
    end

    @desc "[Auth required - Admin only] Upserts a category"
    field :category, :category do
      arg(:id, :integer)

      arg(:category_id, :string, description: "Parent category ID")
      arg(:icon_uri, :string)
      arg(:image_uri, :string)
      arg(:name, non_null(:string))
      arg(:description, non_null(:string))
      arg(:slug, :string)
      arg(:meta_title, :string)
      arg(:meta_description, :string)
      arg(:meta_keywords, :string)
      arg(:categories, non_null(list_of(non_null(:integer))))

      middleware(Middleware.AdminAuthenticate)
      resolve(&Shop.upsert_category/3)
    end

    @desc "[Auth required - Admin only] Upserts a category"
    field :delete_category, :delete_status do
      arg(:id, non_null(:integer))

      middleware(Middleware.AdminAuthenticate)
      resolve(&Shop.delete_category/3)
    end

    @desc "[Auth required] Deletes a product"
    field :delete_product, :delete_status do
      arg(:id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Shop.delete_product/3)
    end
  end

  @desc "Shop subscriptions"
  object(:shop_subscriptions) do
  end

  @desc "Product"
  object(:product) do
    field(:id, non_null(:integer))
    field(:creator_id, non_null(:string))

    field(:community_id, non_null(:string))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:price, non_null(:float))
    field(:track_stock, non_null(:boolean))
    field(:units, :integer)

    field(:images, non_null(list_of(non_null(:product_image))),
      resolve: dataloader(Cambiatus.Shop)
    )

    field(:creator, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))

    field(:categories, non_null(list_of(non_null(:category))), resolve: dataloader(Cambiatus.Shop))

    field(:orders, non_null(list_of(non_null(:order))), resolve: dataloader(Cambiatus.Shop))
  end

  @desc "Product, but in a preview version, simpler and to be used as public"
  object(:product_preview) do
    field(:id, non_null(:integer))
    field(:creator_id, non_null(:string))
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:price, non_null(:float))

    field(:images, non_null(list_of(non_null(:product_image))),
      resolve: dataloader(Cambiatus.Shop)
    )

    field(:community_id, non_null(:string))
    field(:community, non_null(:community_preview), resolve: dataloader(Cambiatus.Commune))
  end

  @desc "Product image"
  object(:product_image) do
    field(:uri, non_null(:string))
  end

  @desc "Product category"
  object(:category) do
    field(:id, non_null(:integer))
    field(:icon_uri, :string)
    field(:image_uri, :string)
    field(:name, non_null(:string))
    field(:description, non_null(:string))

    field(:slug, :string)
    field(:meta_title, :string)
    field(:meta_description, :string)
    field(:meta_keywords, :string)

    field(:category, :category, resolve: dataloader(Cambiatus.Shop))
    field(:categories, list_of(non_null(:category)), resolve: dataloader(Cambiatus.Shop))
    field(:products, list_of(non_null(:product)), resolve: dataloader(Cambiatus.Shop))

    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  @desc "An Order"
  object :order do
    field(:id, non_null(:integer))

    field(:product_id, non_null(:integer))
    field(:product, non_null(:product), resolve: dataloader(Cambiatus.Shop))

    field(:from_id, non_null(:string))
    field(:from, non_null(:user), resolve: dataloader(Cambiatus.Accounts))

    field(:to_id, non_null(:string))
    field(:to, non_null(:user), resolve: dataloader(Cambiatus.Accounts))

    field(:amount, non_null(:float))
    field(:units, :integer)

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  input_object(:products_filter_input) do
    field(:account, non_null(:string))
    field(:in_stock, :boolean)
  end
end
