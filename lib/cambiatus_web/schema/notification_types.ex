defmodule CambiatusWeb.Schema.NotificationTypes do
  @moduledoc """
  GraphQL types for the Notifications context
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Notifications
  alias CambiatusWeb.Schema.Middleware

  @desc "Notification history queries"
  object :notification_queries do
    @desc "[Auth required] User's notifications"
    field(:notification_history, non_null(list_of(non_null(:notification_history)))) do
      middleware(Middleware.Authenticate)
      resolve(&Notifications.user_notification_history/3)
    end
  end

  @desc "Notifications Mutations on Cambiatus"
  object :notification_mutations do
    @desc "[Auth required] Register an push subscription on Cambiatus"
    field(:register_push, non_null(:push_subscription)) do
      arg(:input, non_null(:push_subscription_input))

      middleware(Middleware.Authenticate)
      resolve(&Notifications.register/3)
    end

    @desc "[Auth required] Mark a notification history as read"
    field(:read_notification, non_null(:notification_history)) do
      arg(:input, non_null(:read_notification_input))

      middleware(Middleware.Authenticate)
      resolve(&Notifications.read_notification/3)
    end
  end

  @desc "Notifications Subscriptions on Cambiatus"
  object :notifications_subscriptions do
    @desc "A subscription for the number of unread notifications"
    field :unreads, non_null(:unread_notifications) do
      arg(:input, non_null(:unread_notifications_subscription_input))

      config(fn %{input: %{account: acc}}, _ ->
        # Publish initial results async will run after current stack
        Task.async(fn -> Cambiatus.Notifications.update_unread(acc) end)

        # Accept subscription will run before above line
        {:ok, topic: acc}
      end)

      resolve(fn unreads, _, _ ->
        {:ok, unreads}
      end)
    end
  end

  @desc "A push subscription object"
  object :push_subscription do
    field(:account_id, :string)
    field(:id, :id)
  end

  @desc "An unread notifications object"
  object :unread_notifications do
    field(:unreads, non_null(:integer))
  end

  @desc "Input object to collect number of unread notifications"
  input_object :unread_notifications_subscription_input do
    field(:account, non_null(:string))
  end

  @desc "Input object to mark notification history as read"
  input_object :read_notification_input do
    field(:id, non_null(:integer))
  end

  @desc "Input object for registering a push subscription"
  input_object :push_subscription_input do
    field(:auth_key, non_null(:string))
    field(:endpoint, non_null(:string))
    field(:p_key, non_null(:string))
  end

  @desc "A notification history object"
  object :notification_history do
    field(:id, non_null(:integer))
    field(:recipient_id, non_null(:string))
    field(:recipient, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:type, non_null(:string))
    field(:payload, non_null(:notification_type), resolve: &Notifications.get_payload/3)
    field(:is_read, non_null(:boolean))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  union(:notification_type) do
    types([:transfer, :order, :mint])

    resolve_type(fn
      %Cambiatus.Commune.Transfer{}, _ ->
        :transfer

      %Cambiatus.Shop.Order{}, _ ->
        :order

      %Cambiatus.Commune.Mint{}, _ ->
        :mint
    end)
  end
end
