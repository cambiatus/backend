defmodule CambiatusWeb.Schema.AccountTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the Accounts context in `Cambiatus`
  use it to define entities to be used with the Accounts Context
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias CambiatusWeb.Resolvers.Accounts

  @desc "Accounts Queries"
  object :account_queries do
    @desc "A users profile"
    field :profile, :profile do
      arg(:input, non_null(:profile_input))
      resolve(&Accounts.get_profile/3)
    end

    connection field(:payment_history, node_type: :transfer) do
      arg(:input, non_null(:payment_history_input))
      resolve(&Accounts.get_payment_history/3)
    end
  end

  @desc "Input object for fetching the Payment History: payments from various payer/payers to the recipient."
  input_object(:payment_history_input) do
    field(:recipient, non_null(:string))
    field(:payer, :string)
    field(:date, :date)
  end

  @desc "Account Mutations"
  object :account_mutations do
    @desc "A mutation to update a user's profile"
    field :update_profile, :profile do
      arg(:input, non_null(:profile_update_input))
      resolve(&Accounts.update_profile/3)
    end
  end

  @desc "An input object for updating a user Profile"
  input_object :profile_update_input do
    field(:account, non_null(:string))
    field(:name, :string)
    field(:email, :string)
    field(:bio, :string)
    field(:location, :string)
    field(:interests, :string)
    field(:avatar, :string)
  end

  @desc "Input Object for fetching a User Profile"
  input_object :profile_input do
    field(:account, :string)
  end

  @desc "A users profile on the system"
  object :profile do
    field(:account, non_null(:string))
    field(:name, :string)
    field(:email, :string)
    field(:bio, :string)
    field(:location, :string)
    field(:interests, :string)
    field(:chat_user_id, :string)
    field(:chat_token, :string)
    field(:avatar, :string)
    field(:created_block, :integer)
    field(:created_at, :string)
    field(:created_eos_account, :string)
    field(:network, list_of(:network))

    field(:communities, non_null(list_of(non_null(:community))),
      resolve: dataloader(Cambiatus.Commune)
    )

    field(:invitations, list_of(:string))

    field(:analysis_count, non_null(:integer), resolve: &Accounts.get_analysis_count/3)

    @desc "List of payers to the given recipient fetched by the part of the account name."
    field(:get_payers_by_account, list_of(:profile)) do
      arg(:account, non_null(:string))
      resolve(&Accounts.get_payers_by_account/3)
    end

    connection field(:transfers, node_type: :transfer) do
      resolve(&Accounts.get_transfers/3)
    end
  end
end
