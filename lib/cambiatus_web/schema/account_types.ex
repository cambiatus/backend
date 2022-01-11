defmodule CambiatusWeb.Schema.AccountTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the Accounts context in `Cambiatus`
  use it to define entities to be used with the Accounts Context
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Accounts, as: AccountsResolver
  alias CambiatusWeb.Schema.Middleware

  @desc "Accounts Queries"
  object(:account_queries) do
    @desc "[Auth required] A user"
    field :user, :user do
      arg(:account, non_null(:string))

      middleware(Middleware.Authenticate)
      resolve(&AccountsResolver.get_user/3)
    end
  end

  @desc "Account Mutations"
  object(:account_mutations) do
    @desc "[Auth required] A mutation to update a user"
    field :update_user, :user do
      arg(:input, non_null(:user_update_input))

      middleware(Middleware.Authenticate)
      resolve(&AccountsResolver.update_user/3)
    end

    @desc "Creates a new user account"
    field :sign_up, :session do
      arg(:name, non_null(:string), description: "User's Full name")

      arg(:account, non_null(:string),
        description: "EOS Account, must have 12 chars long and use only [a-z] and [0-5]"
      )

      arg(:email, non_null(:string), description: "User's email")

      arg(:public_key, non_null(:string),
        description: "EOS Account public key, used for creating a new account"
      )

      arg(:password, non_null(:string))

      arg(:user_type, non_null(:string),
        description:
          "User type informs if its a 'natural' or 'juridical' user for regular users and companies"
      )

      arg(:invitation_id, :string,
        description: "Optional, used to auto invite an user to a community"
      )

      arg(:kyc, :kyc_data_update_input, description: "Optional, KYC data")
      arg(:address, :address_update_input, description: "Optional, Address data")

      resolve(&AccountsResolver.sign_up/3)
    end

    field :sign_in, :session do
      arg(:account, non_null(:string))
      arg(:password, non_null(:string))

      arg(:invitation_id, :string,
        description: "Optional, used to auto invite an user to a community"
      )

      resolve(&AccountsResolver.sign_in/3)
    end
  end

  @desc "An input object for updating the current logged User"
  input_object(:user_update_input) do
    field(:name, :string, description: "Optional, name displayed on the app")

    field(:email, :string,
      description:
        "Optional, used for contacting only, must be a valid email but we dont check for ownership"
    )

    field(:bio, :string, description: "Optional, short bio to let others know more about you")
    field(:location, :string, description: "Optional, location, can be virtual or real")
    field(:interests, :string, description: "Optional, a list of strings interpolated with `-`")
    field(:avatar, :string, description: "Optional, URL that must be used as an avatar")

    field(:contacts, list_of(non_null(:contact_input)),
      description:
        "Optional, list will overwrite all entries, ensure to send all contact information"
    )
  end

  input_object(:contact_input) do
    field(:type, :contact_type)
    field(:external_id, :string)
  end

  input_object(:transfer_direction) do
    field(:other_account, :string, description: "Optional other account on the transfer")

    field(:direction, :transfer_direction_value,
      description: "If the user is receiving or sending the transaction"
    )
  end

  @desc "The direction of the transfer"
  enum(:transfer_direction_value) do
    value(:sending, description: "User's sent transfers.")
    value(:receiving, description: "User's received transfers.")
  end

  @desc "Session object, contains the user and a token used to authenticate requests"
  object :session do
    field(:user, non_null(:user))
    field(:token, non_null(:string))
  end

  @desc "User's address"
  object(:address) do
    field(:country, non_null(:country), resolve: dataloader(Cambiatus.Kyc))
    field(:state, non_null(:state), resolve: dataloader(Cambiatus.Kyc))
    field(:city, non_null(:city), resolve: dataloader(Cambiatus.Kyc))
    field(:neighborhood, non_null(:neighborhood), resolve: dataloader(Cambiatus.Kyc))
    field(:street, non_null(:string))
    field(:number, :string)
    field(:zip, non_null(:string))
  end

  @desc "A users on the system"
  object(:user) do
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
    field(:network, list_of(:network), resolve: dataloader(Cambiatus.Commune))
    field(:roles, non_null(list_of(non_null(:role))), resolve: dataloader(Cambiatus.Commune))

    field(:address, :address, resolve: dataloader(Cambiatus.Kyc))
    field(:kyc, :kyc_data, resolve: dataloader(Cambiatus.Kyc))

    field(:contacts, non_null(list_of(non_null(:contact))),
      resolve: dataloader(Cambiatus.Accounts)
    )

    field(:communities, non_null(list_of(non_null(:community))),
      resolve: dataloader(Cambiatus.Commune)
    )

    field(:products, non_null(list_of(:product)), resolve: dataloader(Cambiatus.Shop))
    field(:analysis_count, non_null(:integer), resolve: &AccountsResolver.get_analysis_count/3)

    field(:contribution_count, non_null(:integer)) do
      arg(:community_id, :string,
        description:
          "Optional community filter, filling this will get only contributions from this community"
      )

      resolve(&AccountsResolver.get_contribution_count/3)
    end

    field(:contributions, non_null(list_of(non_null(:contribution)))) do
      arg(:community_id, :string)
      arg(:status, :contribution_status_type)

      resolve(dataloader(Cambiatus.Payments))
    end

    field(:claims, non_null(list_of(non_null(:claim)))) do
      arg(:community_id, :string,
        description:
          "Optional community filter, filling this will get only claims from this community"
      )

      resolve(dataloader(Cambiatus.Commune))
    end

    @desc "List of payers to the given recipient fetched by the part of the account name."
    field(:get_payers_by_account, list_of(:user)) do
      arg(:account, non_null(:string))
      resolve(&AccountsResolver.get_payers_by_account/3)
    end

    connection field(:transfers, node_type: :transfer) do
      arg(:filter, :transfer_filter, description: "Optional Filters for querying transfers")

      resolve(&AccountsResolver.get_transfers/3)
    end
  end

  input_object :transfer_filter do
    field(:date, :date, description: "The date of the transfer in `yyyy-mm-dd` format.")

    field(:direction, :transfer_direction,
      description: "If the user is receiving or sending the transaction"
    )

    field(:community_id, :string,
      description: "optional filter for querying transfers from a community"
    )
  end

  @desc """
  Contact information for an user. Everytime contact is updated it replaces all entries
  """
  object(:contact) do
    field(:type, :contact_type)
    field(:external_id, :string)
  end

  enum(:contact_type) do
    value(:phone, description: "A regular phone number")

    value(:whatsapp,
      description: "A phone number used in Whatsapp. Regular international phone number"
    )

    value(:telegram,
      description:
        "An username or phone number for Telegram. Must be https://t.me/${username} or https://telegram.org/${username}"
    )

    value(:instagram,
      description:
        "An Instagram account. Must have full URL like https://instagram.com/${username}"
    )
  end
end
