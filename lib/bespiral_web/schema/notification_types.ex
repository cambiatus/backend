defmodule BeSpiralWeb.Schema.NotificationTypes do
  @moduledoc """
  GraphQL types for the Notifications context
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

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

  @desc "Notification history queries"
  object :notification_queries do
    field(:notification_history, non_null(list_of(non_null(:notification_history)))) do
      arg(:account, non_null(:string))
      resolve(&Notifications.user_notification_history/3)
    end
  end

  object :notification_history do
    field(:recipient_id, non_null(:string))
    field(:recipient, non_null(:profile), resolve: dataloader(BeSpiral.Commune))
    field(:type, non_null(:string))
    field(:payload, non_null(:string))
    field(:is_read, non_null(:boolean))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
