defmodule CambiatusWeb.Schema.CommuneTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the `Cambiatus.Commune` context
  use it to define entities to be used with the Commune Context
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias CambiatusWeb.Resolvers.Commune

  @desc "Community Queries on Cambiatus"
  object :community_queries do
    @desc "A list of sales in Cambiatus"
    field :sales, non_null(list_of(non_null(:sale))) do
      arg(:input, non_null(:sales_input))
      resolve(&Commune.get_sales/3)
    end

    @desc "A list of communities in Cambiatus"
    field :communities, non_null(list_of(non_null(:community))) do
      resolve(&Commune.get_communities/3)
    end

    @desc "A single community"
    field :community, :community do
      arg(:symbol, non_null(:string))
      resolve(&Commune.find_community/3)
    end

    @desc "A list of sale history"
    field :sale_history, list_of(:sale_history) do
      resolve(&Commune.get_sales_history/3)
    end

    @desc "A single sale from Cambiatus"
    field :sale, :sale do
      arg(:input, non_null(:sale_input))
      resolve(&Commune.get_sale/3)
    end

    @desc "A list of claims"

    connection field(:claims, node_type: :claim) do
      arg(:input, non_null(:claims_input))
      resolve(&Commune.get_claims/3)
    end

    @desc "A single claim"
    field :claim, non_null(:claim) do
      arg(:input, non_null(:claim_input))
      resolve(&Commune.get_claim/3)
    end

    @desc "A single objective"
    field :objective, :objective do
      arg(:input, non_null(:objective_input))
      resolve(&Commune.get_objective/3)
    end

    @desc "A single Transfer"
    field :transfer, :transfer do
      arg(:input, non_null(:transfer_input))
      resolve(&Commune.get_transfer/3)
    end

    @desc "An invite"
    field :invite, :invite do
      arg(:input, non_null(:invite_input))
      resolve(&Commune.get_invitation/3)
    end
  end

  @desc "Community mutations on Cambiatus"
  object :community_mutations do
    @desc "A mutation to update a community's enabled features"
    field :update_features, :features do
      arg(:input, non_null(:features_update_input))
      resolve(&Commune.update_features/3)
    end
  end

  @desc "Input object for updating a community's enabled features"
  input_object :features_update_input do
    field(:community, non_null(:string))
    field(:actions, :boolean)
    field(:shop, :boolean)
  end

  @desc "Community Subscriptions on Cambiatus"
  object :community_subscriptions do
    @desc "A subscription to resolve operations on the sales table"
    field :sales_operation, :sale do
      deprecate("Use push notifications to receive these updates")

      config(fn _args, _info ->
        {:ok, topic: "*"}
      end)
    end

    @desc "A subscription for sale history"
    field :sale_history_operation, :sale_history do
      deprecate("Use push notifications to receive these updates")

      config(fn _args, _info ->
        {:ok, topic: "*"}
      end)
    end

    @desc "A subscription for transfers"
    field :transfers, :transfer do
      deprecate("Use push notifications to receive these updates")

      config(fn _args, _info ->
        {:ok, topic: "*"}
      end)
    end

    @desc "A subscription for new community addition"
    field :newcommunity, non_null(:community) do
      arg(:input, non_null(:new_community_input))

      config(fn %{input: %{symbol: sym}}, _ ->
        {:ok, topic: sym}
      end)

      resolve(fn community, _, _ ->
        {:ok, community}
      end)
    end

    field :transfersucceed, non_null(:transfer) do
      arg(:input, non_null(:transfer_succeed_input))

      config(fn %{input: %{from: from, to: to, symbol: s}}, _ ->
        {:ok, topic: "#{s}-#{from}-#{to}"}
      end)

      resolve(fn transfer, _, _ ->
        {:ok, transfer}
      end)
    end
  end

  input_object :transfer_succeed_input do
    field(:from, non_null(:string))
    field(:to, non_null(:string))
    field(:symbol, non_null(:string))
  end

  @desc "Input to subscribe for a new community creation"
  input_object :new_community_input do
    field(:symbol, non_null(:string))
  end

  @desc "Input object to collect a single Objective"
  input_object :objective_input do
    field(:id, non_null(:integer))
  end

  @desc "Input to collect claims"
  input_object :claims_input do
    field(:validator, :string)
    field(:claimer, :string)
    field(:symbol, :string)
    field(:all, :boolean)
  end

  @desc "Input to collect a sale"
  input_object :sale_input do
    field(:id, non_null(:integer))
  end

  @desc "Input for run transfer"
  input_object :transfer_input do
    field(:id, non_null(:integer))
  end

  @desc "Input to collect sales"
  input_object :sales_input do
    field(:account, :string)
    field(:community_id, :string)
    field(:communities, :string)
    field(:all, :string)
  end

  @desc "Input to collect a claim"
  input_object :claim_input do
    field(:id, non_null(:integer))
  end

  @desc "Input to collect a user's transfers"
  input_object :transfers_input do
    field(:account, :string)
    field(:symbol, :string)
  end

  @desc "Input to collect a user's related actions"
  input_object :actions_input do
    field(:creator, :string)
    field(:validator, :string)
    field(:is_completed, :boolean)
    field(:verification_type, :verification_type)
  end

  @desc "Input to collect checks"
  input_object :checks_input do
    field(:validator, :string)
  end

  @desc "Input to collect an invite"
  input_object :invite_input do
    field(:id, :string)
  end

  @desc "A mint object in Cambiatus"
  object :mint do
    field(:memo, :string)
    field(:quantity, non_null(:float))
    field(:to, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A community on Cambiatus"
  object :community do
    field(:symbol, non_null(:string))
    field(:creator, non_null(:string))
    field(:logo, non_null(:string))
    field(:name, non_null(:string))
    field(:description, non_null(:string))
    field(:inviter_reward, non_null(:float))
    field(:invited_reward, non_null(:float))

    field(:type, :string)
    field(:issuer, :string)
    field(:supply, :float)
    field(:max_supply, :float)
    field(:min_balance, :float)

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))

    connection field(:transfers, node_type: :transfer) do
      resolve(&Commune.get_transfers/3)
    end

    field(:objectives, non_null(list_of(non_null(:objective))),
      resolve: dataloader(Cambiatus.Commune)
    )

    field(:mints, non_null(list_of(non_null(:mint))), resolve: dataloader(Cambiatus.Commune))
    field(:members, non_null(list_of(non_null(:profile))), resolve: dataloader(Cambiatus.Commune))
    field(:member_count, non_null(:integer), resolve: &Commune.get_members_count/3)
    field(:transfer_count, non_null(:integer), resolve: &Commune.get_transfer_count/3)
    field(:sale_count, non_null(:integer), resolve: &Commune.get_sale_count/3)
    field(:action_count, non_null(:integer), resolve: &Commune.get_action_count/3)
    field(:features, non_null(:features), resolve: &Commune.get_features/3)
  end

  @desc "The community's enabled features"
  object :features do
    field(:actions, non_null(:boolean))
    field(:shop, non_null(:boolean))
  end

  @desc "A community objective"
  object :objective do
    field(:id, non_null(:integer))
    field(:description, non_null(:string))
    field(:creator_id, non_null(:string))

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))

    field(:creator, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:actions, non_null(list_of(non_null(:action)))) do
      arg(:input, :actions_input)
      resolve(dataloader(Cambiatus.Commune))
    end
  end

  @desc "An Action for reaching an objective"
  object :action do
    field(:id, non_null(:integer))
    field(:description, non_null(:string))
    field(:creator_id, non_null(:string))
    field(:reward, non_null(:float))
    field(:verifier_reward, non_null(:float))
    field(:deadline, :datetime)
    field(:usages, non_null(:integer))
    field(:usages_left, non_null(:integer))
    field(:verifications, non_null(:integer))
    field(:is_completed, non_null(:boolean))
    field(:verification_type, non_null(:verification_type))

    field(:objective, non_null(:objective), resolve: dataloader(Cambiatus.Commune))

    field(:validators, non_null(list_of(non_null(:profile))),
      resolve: dataloader(Cambiatus.Commune)
    )

    field(:claims, non_null(list_of(non_null(:claim))), resolve: dataloader(Cambiatus.Commune))
    field(:creator, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A claim made in an action"
  object :claim do
    field(:id, non_null(:integer))
    field(:action, non_null(:action), resolve: dataloader(Cambiatus.Commune))
    field(:claimer, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:is_verified, non_null(:boolean))

    field(:checks, non_null(list_of(non_null(:check)))) do
      arg(:input, :checks_input)
      resolve(dataloader(Cambiatus.Commune))
    end

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A check for a given claim"
  object :check do
    field(:claim, non_null(:claim), resolve: dataloader(Cambiatus.Commune))
    field(:validator, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:is_verified, non_null(:boolean))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A network in Cambiatus"
  object :network do
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
    field(:community, :community)
    field(:account, :profile)
    field(:invited_by, :string)
  end

  @desc "A sale on Cambiatus"
  object :sale do
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

    field(:creator, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A sale history"
  object :sale_history do
    field(:id, non_null(:integer))
    field(:community_id, non_null(:string))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:sale_id, non_null(:integer))
    field(:sale, non_null(:sale), resolve: dataloader(Cambiatus.Commune))

    field(:from_id, non_null(:string))
    field(:from, non_null(:profile), resolve: dataloader(Cambiatus.Commune))

    field(:to_id, non_null(:string))
    field(:to, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:amount, non_null(:float))
    field(:units, :integer)
  end

  @desc "A transfer on Cambiatus"
  object :transfer do
    field(:id, non_null(:integer))
    field(:from_id, non_null(:string))
    field(:to_id, non_null(:string))
    field(:amount, non_null(:float))
    field(:community_id, non_null(:string))
    field(:memo, :string)
    field(:from, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:to, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A community invite"
  object :invite do
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))
    field(:creator, non_null(:profile), resolve: dataloader(Cambiatus.Commune))
  end

  @desc "Action verification types"
  enum :verification_type do
    value(:automatic, as: "automatic", description: "An action that is verified automatically")
    value(:claimable, as: "claimable", description: "An action that needs be mannually verified")
  end
end
