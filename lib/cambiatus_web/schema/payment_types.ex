defmodule CambiatusWeb.Schema.PaymentTypes do
  @moduledoc """
  GraphQL objects related to our Payment processing
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Payment, as: PaymentResolver
  alias CambiatusWeb.Schema.Middleware

  @desc "Queries to payment stuff, like Paypal and crypto processing"
  object :payment_queries do
  end

  object :payment_mutations do
    @desc "[Auth required] Create a new contribution"
    field(:contribution, :contribution) do
      arg(:amount, non_null(:float))
      arg(:currency, non_null(:currency_type))
      arg(:community_id, non_null(:string))

      middleware(Middleware.Authenticate)
      resolve(&PaymentResolver.create_contribution/3)
    end
  end

  object(:contribution) do
    field(:id, non_null(:string))
    field(:amount, non_null(:float))
    field(:currency, non_null(:currency_type))
    field(:payment_method, non_null(:payment_method_type))
    field(:status, non_null(:contribution_status_type))

    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))

    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))
    field(:user, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
  end

  object(:contribution_config) do
    field(:accepted_currencies, non_null(list_of(non_null(:currency_type))))
    field(:paypal_account, :string)
    field(:thank_you_title, :string)
    field(:thank_you_description, :string)
  end

  enum(:currency_type) do
    value(:USD, description: "US dollars")
    value(:BRL, description: "Brazil Reais")
    value(:CRC, description: "Costa Rica Colones")
    value(:BTC, description: "Bitcoin")
    value(:ETH, description: "Ethereum")
    value(:EOS, description: "EOS")
  end

  enum(:payment_method_type) do
    value(:paypal, description: "Paypal, used to process FIAT")
    value(:bitcoin, description: "Bitcoin Mainnet")
    value(:ethereum, description: "Ethereum Mainnet")
    value(:eos, description: "EOS Mainnet")
  end

  enum(:contribution_status_type) do
    value(:created, description: "Created successfully")
    value(:captured, description: "Captured / Received by the external processor")
    value(:approved, description: "Approved by the external processor")
    value(:rejected, description: "Rejected by the external processor")
    value(:failed, description: "Failed")
  end
end
