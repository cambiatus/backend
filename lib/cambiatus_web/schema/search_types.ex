defmodule CambiatusWeb.Schema.SearchTypes do
  @moduledoc """
  Holds all GraphQL Schema Objects related to Search in Cambiatus
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Commune
  alias CambiatusWeb.Schema.Middleware

  @desc "Search queries"
  object(:search_queries) do
    @desc "[Auth required] Searches the community for a product or action"
    field(:search, non_null(:search_result)) do
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
      arg(:query, :string)

      resolve(dataloader(Cambiatus.Accounts))
    end
  end
end
