defmodule CambiatusWeb.Schema.ObjectiveTypes do
  @moduledoc """
  All GraphQL objects related with the `objectives` context
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Schema.Middleware
  alias CambiatusWeb.Resolvers.Objectives

  object :objective_queries do
    @desc "[Auth required] A single claim"
    field :claim, non_null(:claim) do
      arg(:id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Objectives.get_claim/3)
    end

    @desc "[Auth required] A single objective"
    field :objective, :objective do
      arg(:id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Objectives.get_objective/3)
    end
  end

  object :objective_mutations do
    @desc "[Auth required - Admin only] Complete an objective"
    field :complete_objective, :objective do
      arg(:id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Objectives.complete_objective/3)
    end
  end

  @desc "Params for filtering Claims"
  input_object(:claims_filter) do
    field(:claimer, :string)
    field(:status, :string)
    field(:direction, :direction)
  end

  @desc "A mint object in Cambiatus"
  object :mint do
    field(:memo, :string)
    field(:quantity, non_null(:float))
    field(:to, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Commune))

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
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

    field(:is_completed, non_null(:boolean))
    field(:completed_at, :naive_datetime)

    field(:creator, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:community, non_null(:community), resolve: dataloader(Cambiatus.Accounts))

    field(:actions, non_null(list_of(non_null(:action)))) do
      arg(:input, :actions_input)
      resolve(dataloader(Cambiatus.Objectives))
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
    field(:has_proof_photo, :boolean)
    field(:has_proof_code, :boolean)
    field(:photo_proof_instructions, :string)

    field(:position, :integer)

    field(:objective, non_null(:objective), resolve: dataloader(Cambiatus.Objectives))

    field(:validators, non_null(list_of(non_null(:user))), resolve: dataloader(Cambiatus.Accounts))

    field(:claims, non_null(list_of(non_null(:claim))), resolve: dataloader(Cambiatus.Objectives))
    field(:creator, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A claim made in an action"
  object :claim do
    field(:id, non_null(:integer))
    field(:action, non_null(:action), resolve: dataloader(Cambiatus.Objectives))
    field(:claimer, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:status, non_null(:claim_status))
    field(:proof_photo, :string)
    field(:proof_code, :string)

    field(:checks, non_null(list_of(non_null(:check)))) do
      arg(:input, :checks_input)
      resolve(dataloader(Cambiatus.Objectives))
    end

    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "A check for a given claim"
  object :check do
    field(:claim, non_null(:claim), resolve: dataloader(Cambiatus.Objectives))
    field(:validator, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:is_verified, non_null(:boolean))
    field(:created_block, non_null(:integer))
    field(:created_tx, non_null(:string))
    field(:created_eos_account, non_null(:string))
    field(:created_at, non_null(:datetime))
  end

  @desc "Claim possible status"
  enum :claim_status do
    value(:approved, as: "approved")
    value(:rejected, as: "rejected")
    value(:pending, as: "pending")
  end
end
