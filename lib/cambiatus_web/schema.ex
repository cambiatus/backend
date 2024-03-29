defmodule CambiatusWeb.Schema do
  @moduledoc """
  This module holds the implementation for the GraphQL schema for Cambiatus, use this module
  to add and remove middleware from the schema and define its root shape
  """

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :classic

  alias Cambiatus.{Accounts, Commune, Kyc, Payments, Shop, Social, Objectives}

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Commune, Commune.data())
      |> Dataloader.add_source(Accounts, Accounts.data())
      |> Dataloader.add_source(Kyc, Kyc.data())
      |> Dataloader.add_source(Shop, Shop.data())
      |> Dataloader.add_source(Social, Social.data())
      |> Dataloader.add_source(Payments, Payments.data())
      |> Dataloader.add_source(Objectives, Objectives.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.CommuneTypes)
  import_types(__MODULE__.NotificationTypes)
  import_types(__MODULE__.RelayTypes)
  import_types(__MODULE__.KycTypes)
  import_types(__MODULE__.ShopTypes)
  import_types(__MODULE__.SearchTypes)
  import_types(__MODULE__.SocialTypes)
  import_types(__MODULE__.PaymentTypes)
  import_types(__MODULE__.ObjectiveTypes)

  query do
    import_fields(:account_queries)
    import_fields(:community_queries)
    import_fields(:notification_queries)
    import_fields(:address_queries)
    import_fields(:shop_queries)
    import_fields(:search_queries)
    import_fields(:social_queries)
    import_fields(:payment_queries)
    import_fields(:objective_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:notification_mutations)
    import_fields(:kyc_mutations)
    import_fields(:commune_mutations)
    import_fields(:shop_mutations)
    import_fields(:social_mutations)
    import_fields(:payment_mutations)
    import_fields(:objective_mutations)
  end

  subscription do
    import_fields(:community_subscriptions)
    import_fields(:notifications_subscriptions)
    import_fields(:shop_subscriptions)
  end
end
