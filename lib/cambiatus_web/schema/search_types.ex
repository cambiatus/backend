defmodule CambiatusWeb.Schema.SearchTypes do
  @moduledoc """
  Holds all GraphQL Schema Objects related to Search in Cambiatus
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.{Commune, Accounts}
  alias CambiatusWeb.Schema.Middleware

  @desc "Search queries"
  object(:search_queries) do
    @desc "[Auth required] Searches the community for a product or action"
    field(:search, non_null(:search_result)) do
      arg(:community_id, non_null(:string))

      middleware(Middleware.Authenticate)
      resolve(&Commune.search/3)
    end
  end

  object(:search_result) do
    field(:products, non_null(list_of(non_null(:product)))) do
      arg(:query, :string)
      resolve(dataloader(Cambiatus.Shop))
    end

    field(:actions, non_null(list_of(non_null(:action)))) do
      arg(:query, :string)
      resolve(dataloader(Cambiatus.Objectives))
    end

    field(:members, non_null(list_of(non_null(:user)))) do
      arg(:filters, :members_filter_input)
      resolve(&Accounts.search_in_community/3)
    end
  end

  input_object(:members_filter_input) do
    field(:search_string, :string)
    field(:order_by, :order_by_fields, default_value: :name)
    # Field direction defined on CambiatusWeb.Schema.CommuneTypes
    field(:order_direction, :direction, default_value: :desc)
  end

  enum(:order_by_fields) do
    value(:name, name: "name", description: "Order by member name")
    value(:account, name: "account", description: "Order by member account")
    value(:created_at, name: "created_at", description: "Order by member creation date")
  end
end
