defmodule CambiatusWeb.Resolvers.Notifications do
  @moduledoc """
  Resolver functions implementation for the Notifications context
  """
  alias Cambiatus.{Commune, Notifications, Shop}

  @doc """
  Function to register push subscriptions
  """
  @spec register(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def register(_, %{input: params}, %{context: %{current_user: current_user}}) do
    case Notifications.add_push_subscription(current_user, params) do
      {:ok, push} ->
        {:ok, push}

      {:error, changeset} ->
        {:error,
         message: "Could not register subscription", details: Cambiatus.Error.from(changeset)}
    end
  end

  @doc """
  Finds all of the users notifications
  """
  @spec user_notification_history(map(), map(), map()) :: {:ok, list(map())} | {:error, term}
  def user_notification_history(_, _, %{context: %{current_user: current_user}}) do
    Notifications.get_user_notification_history(current_user)
  end

  @spec get_payload(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def get_payload(notification_history, _, _) do
    case Jason.decode(notification_history.payload, keys: :atoms) do
      {:ok, %{record: data}} ->
        case notification_history do
          %{type: "transfer"} ->
            Commune.get_transfer(data.id)

          %{type: "sale_history"} ->
            case Shop.get_order(data.id) do
              nil ->
                {:error, "No Order record with the id: #{data.id} found"}

              val ->
                {:ok, val}
            end

          _ ->
            {:ok, nil}
        end

      _ ->
        {:error, "Failed to parse notification"}
    end
  end

  @doc """
  Count number of unread notifications for a user
  """
  @spec unread_notifications(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def unread_notifications(_, _, %{context: %{current_user: current_user}}) do
    Notifications.get_unread(current_user.account)
  end

  @doc """
  Flag a notification as read
  """
  @spec read_notification(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def read_notification(_, %{input: %{id: id}}, %{context: %{current_user: current_user}}) do
    case Notifications.get_notification_history(current_user, id) do
      {:ok, n} ->
        Notifications.mark_as_read(n)

      {:error, err} ->
        {:error, message: "Could not read given notification", details: Cambiatus.Error.from(err)}
    end
  end
end
