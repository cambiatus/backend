defmodule CambiatusWeb.Schema.KycTypes do
  @moduledoc """
  This module hold GraphQL objects related to the KYC process
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias CambiatusWeb.Resolvers.Kyc

  @desc "Address query"
  object :address_queries do
    @desc "List of supported countries"
    field(:country, :country) do
      arg(:input, non_null(:country_input))
      resolve(&Kyc.get_country/3)
    end
  end

  @desc "Input to query countries"
  input_object(:country_input) do
    field(:name, non_null(:string))
  end

  @desc "KYC supported countries"
  object :country do
    field(:name, non_null(:string))
    field(:states, non_null(list_of(:state)), resolve: dataloader(Kyc))
  end

  @desc "KYC supported states"
  object :state do
    field(:name, non_null(:string))
    # field(:cities, non_null(list_of(:city)), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported cities"
  object :city do
    field(:name, non_null(:string))
    # field(:neighborhoods, non_null(list_of(:neighborhood)), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported neighborhoods"
  object :neighborhood do
    field(:name, non_null(:string))
  end
end
