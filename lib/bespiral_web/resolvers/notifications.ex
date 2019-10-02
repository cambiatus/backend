defmodule BeSpiralWeb.Resolvers.Notifications do
  @moduledoc """
  Resolver functions implementation for the Notifications context
  """
  alias BeSpiral.{
    Accounts,
    Notifications
  }

  @doc """
  Function to register push subscriptions
  """
  @spec register(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def register(_, %{input: params}, _) do
    with {:ok, user} <- Accounts.get_account_profile(params.account),
         {:ok, push} <- Notifications.add_push_subscription(user, params) do
      {:ok, push}
    end
  end

  @doc """
  Finds all of the users notifications
  """
  @spec user_notification_history(map(), map(), map()) :: {:ok, list(map())} | {:error, term}
  def user_notification_history(_, %{account: params}, _) do
    Notifications.get_user_notification_history(params)
  end
end
