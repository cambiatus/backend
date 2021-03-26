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
  end

  @desc "Shop mutations"
  object(:shop_mutations) do
  end

  @desc "Shop subscriptions"
  object(:shop_subscriptions) do
  end

  object(:product) do
    field(:id, non_null(:integer))
    field(:creator_id, non_null(:string))

    field(:community_id, non_null(:string))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:price, non_null(:float))
    field(:image, :string)
    field(:track_stock, non_null(:boolean))
    field(:units, non_null(:integer))

    field(:creator, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))

    field(:orders, non_null(list_of(non_null(:order))), resolve: dataloader(Cambiatus.Shop))
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
