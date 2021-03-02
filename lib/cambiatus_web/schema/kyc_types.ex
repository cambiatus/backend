defmodule CambiatusWeb.Schema.KycTypes do
  @moduledoc """
  This module hold GraphQL objects related to the KYC process
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Kyc
  alias CambiatusWeb.Schema.Middleware

  @desc "Address query"
  object :address_queries do
    @desc "[Auth required] List of supported countries"
    field(:country, :country) do
      arg(:input, non_null(:country_input))

      middleware(Middleware.Authenticate)
      resolve(&Kyc.get_country/3)
    end
  end

  @desc "Kyc data mutations"
  object :kyc_mutations do
    @desc "[Auth required] Updates user's KYC info if it already exists or inserts a new one if user hasn't it yet."
    field :upsert_kyc, :kyc_data do
      arg(:input, non_null(:kyc_data_update_input))

      middleware(Middleware.Authenticate)
      resolve(&Kyc.upsert_kyc/3)
    end

    @desc "[Auth required] Updates user's address if it already exists or inserts a new one if user hasn't it yet."
    field :upsert_address, :address do
      arg(:input, non_null(:address_update_input))

      middleware(Middleware.Authenticate)
      resolve(&Kyc.upsert_address/3)
    end

    @desc "[Auth required] A mutation to delete user's kyc data"
    field :delete_kyc, :delete_kyc_address do
      middleware(Middleware.Authenticate)
      resolve(&Kyc.delete_kyc/3)
    end

    @desc "[Auth required] A mutation to delete user's address data"
    field :delete_address, :delete_kyc_address do
      middleware(Middleware.Authenticate)
      resolve(&Kyc.delete_address/3)
    end
  end

  @desc "Input to query countries"
  input_object(:country_input) do
    field(:name, non_null(:string))
  end

  @desc "KYC supported countries"
  object :country do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:states, non_null(list_of(non_null(:state))), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported states"
  object :state do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:cities, non_null(list_of(non_null(:city))), resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "KYC supported cities"
  object :city do
    field(:id, non_null(:id))
    field(:name, non_null(:string))

    field(:neighborhoods, non_null(list_of(non_null(:neighborhood))),
      resolve: dataloader(Cambiatus.Kyc)
    )
  end

  @desc "KYC supported neighborhoods"
  object :neighborhood do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
  end

  @desc "User's KYC fields"
  object :kyc_data do
    field(:user_type, non_null(:string))
    field(:document_type, non_null(:string))
    field(:document, non_null(:string))
    field(:phone, non_null(:string))
    field(:is_verified, non_null(:boolean))
    field(:country, :country, resolve: dataloader(Cambiatus.Kyc))
  end

  @desc "Input for creating/updating KYC fields"
  input_object :kyc_data_update_input do
    field(:country_id, non_null(:id))
    field(:user_type, non_null(:string))
    field(:document_type, non_null(:string))
    field(:document, non_null(:string))
    field(:phone, non_null(:string))
  end

  @desc "Input for creating/updating address fields"
  input_object :address_update_input do
    field(:country_id, non_null(:id))
    field(:state_id, non_null(:id))
    field(:city_id, non_null(:id))
    field(:neighborhood_id, non_null(:id))
    field(:street, non_null(:string))
    field(:number, :string)
    field(:zip, non_null(:string))
  end

  @desc "Object status for deleting KYC & Address"
  object :delete_kyc_address do
    field(:status, non_null(:string))
    field(:reason, non_null(:string))
  end
end
