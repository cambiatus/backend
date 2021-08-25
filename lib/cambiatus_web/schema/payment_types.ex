defmodule CambiatusWeb.Schema.PaymentTypes do
  @moduledoc """
  GraphQL objects related to our Payment processing
  """

  use Absinthe.Schema.Notation
  alias CambiatusWeb.Schema.Middleware

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Payment, as: PaymentResolver

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
    field(:amount, non_null(:float))
    field(:currency, non_null(:currency_type))
    field(:payment_method, non_null(:payment_method_type))
    field(:status, non_null(:contribution_status_type))

    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Accounts))
    field(:user, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
  end

  enum(:currency_type) do
    value(:usd, description: "US dollars")
    value(:brl, description: "Brazil Reais")
    value(:crc, description: "Costa Rica Colones")
    value(:btc, description: "Bitcoin")
    value(:eth, description: "Ethereum")
    value(:eos, description: "EOS")
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
