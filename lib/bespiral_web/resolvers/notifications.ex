defmodule BeSpiralWeb.Resolvers.Notifications do
  @moduledoc """
  Resolver functions implementation for the Notifications context
  """
  alias BeSpiral.{
    Accounts,
    Commune.Transfer,
    Commune.SaleHistory,
    Notifications,
    Repo
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

  @spec get_payload(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def get_payload(notification_history, _, _) do
    with {:ok, %{record: data}} <- notification_history.payload |> Jason.decode(keys: :atoms) do
      case notification_history do
        %{type: "transfer"} ->
          {:ok, Repo.get(Transfer, data.id)}

        %{type: "sale_history"} ->
          {:ok, Repo.get(SaleHistory, data.id)}

        _ ->
          {:ok, nil}
      end
    else
      _ ->
        {:error, "Failed to parse notification"}
    end
  end

  @doc """
  Count number of unread notifications for a user
  """
  @spec unread_notifications(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def unread_notifications(_, %{input: %{account: acc}}, _) do
    Notifications.get_unread(acc)
  end

  @doc """
  Flag a notification as read
  """
  @spec read_notification(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def read_notification(_, %{input: %{id: id}}, _) do
    with {:ok, n} <- Notifications.get_notification_history(id) do
      Notifications.mark_as_read(n)
    else
      {:error, err} ->
        {:error, err}
    end
  end
end
