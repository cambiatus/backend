defmodule BeSpiralWeb.Schema.NotificationTypes do
  @moduledoc """
  GraphQL types for the Notifications context
  """
  use Absinthe.Schema.Notation
  alias BeSpiralWeb.Resolvers.Notifications

  @desc "Notifications Mutations on BeSpiral"
  object :notification_mutations do
    @desc "Register an push subscription on BeSpiral"
    field(:register_push, non_null(:push_subscription)) do
      arg(:input, non_null(:push_subscription_input))
      resolve(&Notifications.register/3)
    end
  end

  @desc "A push subscription object"
  object :push_subscription do
    field(:account_id, :string)
    field(:id, :id)
  end

  @desc "Input object for registering a push subscription"
  input_object :push_subscription_input do
    field(:account, non_null(:string))
    field(:auth_key, non_null(:string))
    field(:endpoint, non_null(:string))
    field(:p_key, non_null(:string))
  end
end
