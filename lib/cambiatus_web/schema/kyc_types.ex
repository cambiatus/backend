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
    field(:states, non_null(list_of(:state)), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported states"
  object :state do
    field(:name, non_null(:string))
    field(:cities, non_null(list_of(:city)), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported cities"
  object :city do
    field(:name, non_null(:string))
    field(:neighborhoods, non_null(list_of(:neighborhood)), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported neighborhoods"
  object :neighborhood do
    field(:name, non_null(:string))
  end

  @desc "User's KYC fields"
  object :kyc_data do
    field(:user_type, :string)
    field(:document, :string)
    field(:document_type)
    field(:phone, :string)
    field(:is_verified, :boolean)
    field(:country, :country, resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "Input for user's KYC data deletion"
  input_object :kyc_data_deletion do
    field(:account_id, non_null(:string))
    field(:country_id, non_null(:string))
    field(:user_type, non_null(:string))
    field(:document_type, non_null(:string))
    field(:document, non_null(:string))
    field(:phone, non_null(:string))
  end

  @desc "Kyc data mutations"
  object :kyc_mutations do
    @desc "A mutation to delete user's kyc data"
    field :kyc_data_deletion, :kyc_data do
      arg(:input, non_null(:kyc_data_deletion))
      resolve(&Kyc.kyc_data_deletion/3)
    end
  end
end
