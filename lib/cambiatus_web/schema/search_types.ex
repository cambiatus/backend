defmodule CambiatusWeb.Schema.SearchTypes do
  @moduledoc """
  Holds all GraphQL Schema Objects related to Search in Cambiatus
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Commune

  @desc "Search queries"
  object(:search_queries) do
    field(:search, non_null(:search_result)) do
      arg(:community_id, non_null(:string))
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
      resolve(dataloader(Cambiatus.Shop))
    end
  end
end
