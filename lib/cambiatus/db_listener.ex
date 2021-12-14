defmodule Cambiatus.DbListener do
  @moduledoc """
  Long running process that listens to the Database for triggers on subscribed rows
  """
  use GenServer
  require Logger

  alias Cambiatus.{Accounts, Notifications, Repo, Objectives}
  alias Cambiatus.Commune.Transfer
  alias Cambiatus.Objectives.Claim

  alias CambiatusWeb.Endpoint

  @typep callback_return :: {:noreply, :event_handled} | {:noreply, :error_handled}

  @doc """
  Child spec for starting our genserver from the application level supervisor
  """
  @spec child_spec(list()) :: map()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc """
  Start link function for starting the Listener GenServer
  """
  @spec start_link(list()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Function to initialize our GenServer in a predictable state
  """
  @spec init(list()) :: {:ok, list()} | {:stop, term()}
  def init(opts) do
    with {:ok, _pid, _ref} <- Repo.listen("transfers_changed"),
         {:ok, _pid, _ref} <- Repo.listen("sale_history_changed"),
         {:ok, _pid, _ref} <- Repo.listen("claims_changed"),
         {:ok, _pid, _ref} <- Repo.listen("check_added"),
         {:ok, _pid, _ref} <- Repo.listen("community_created"),
         {:ok, _pid, _ref} <- Repo.listen("notifications_updated"),
         {:ok, _pid, _ref} <- Repo.listen("mints_modified") do
      {:ok, opts}
    else
      error ->
        Sentry.capture_message("Error Starting Cambiatus.DbListener", extra: error)

        {:stop, error}
    end
  end

  @doc """
  Callback Spec
  """
  @spec handle_info(tuple(), term()) :: callback_return()
  def handle_info(details, state)

  def handle_info({:notification, _, _, "transfers_changed", payload}, _state) do
    with {:ok, %{record: record}} <- Jason.decode(payload, keys: :atoms),
         {:ok, record} <- format_record(Transfer, record),
         {:ok, account} <- Accounts.get_account_profile(record.to_id),
         {:ok, user_subs} <- Notifications.get_subscriptions(account),
         :ok <-
           Absinthe.Subscription.publish(Endpoint, record,
             transfersucceed: "#{record.community_id}-#{record.from_id}-#{record.to_id}"
           ) do
      message =
        "Transfer of #{record.amount} #{record.community_id} from #{record.from_id} received"

      notification = %{type: :transfer, title: "Transfer from #{record.from_id}", body: message}
      # Analyse responses from sending push subs
      _ =
        Enum.map(user_subs, fn sub ->
          resp = Notifications.send_push(notification, sub)
          Logger.info("Send push results: #{inspect(resp)}")
        end)

      # Save notification history for both the sender and the receiver of the transaction
      %{
        recipient_id: record.from_id,
        type: "transfer",
        payload: payload
      }
      |> Notifications.create_notification_history()

      %{
        recipient_id: record.to_id,
        type: "transfer",
        payload: payload
      }
      |> Notifications.create_notification_history()

      # Trigger email delivery as well
      CambiatusWeb.Email.transfer(record)

      {:noreply, :event_handled}
    else
      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _pid, _ref, "sale_history_changed", payload}, _state) do
    case Jason.decode(payload, keys: :atoms) do
      {:ok, data} ->
        # After the notification has been sent, save it on the notification history table
        %{
          recipient_id: data.record.to_id,
          type: "sale_history",
          payload: payload
        }
        |> Notifications.create_notification_history()

        %{
          recipient_id: data.record.from_id,
          type: "sale_history",
          payload: payload
        }
        |> Notifications.create_notification_history()

        {:noreply, :event_handled}

      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _, _, "claims_changed", payload}, _state) do
    with {:ok, %{record: record, operation: "INSERT"}} <- Jason.decode(payload, keys: :atoms),
         {:ok, action} <- Objectives.get_action(record.action_id),
         {:ok, :notified} <- Notifications.notify_validators(action) do
      {:noreply, :event_handled}
    else
      {:ok, %{record: record, operation: "UPDATE"}} ->
        if record.status == "approved" do
          claim =
            Claim
            |> Repo.get(record.id)
            |> Repo.preload(action: [objective: [community: :subdomain]])
            |> Repo.preload(:claimer)

          CambiatusWeb.Email.claim(claim)
          Notifications.notify_claim_approved(record.id)
        end

      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _, _, "check_added", payload}, _state) do
    with {:ok, %{record: record}} <- Jason.decode(payload, keys: :atoms),
         {:ok, claim} <- Objectives.get_claim(record.claim_id),
         {:ok, :notified} <- Notifications.notify_claimer(claim) do
      {:noreply, :event_handled}
    else
      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _pid, _ref, "community_created", payload}, _state) do
    with {:ok, %{record: record}} <- Jason.decode(payload, keys: :atoms),
         :ok <- Absinthe.Subscription.publish(Endpoint, record, newcommunity: record.symbol) do
      {:noreply, :event_handled}
    else
      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _pid, _ref, "notifications_updated", payload}, _state) do
    with {:ok, %{record: record}} <- Jason.decode(payload, keys: :atoms),
         :ok <- Notifications.update_unread(record.recipient_id) do
      {:noreply, :event_handled}
    else
      err ->
        log_sentry_error(err)
    end
  end

  def handle_info({:notification, _pid, _ref, "mints_modified", payload}, _state) do
    with {:ok, %{record: mint}} <- Jason.decode(payload, keys: :atoms),
         {:ok, :notified} <- Notifications.notify_mintee(mint) do
      # Log notification
      %{
        recipient_id: mint.to_id,
        type: "mint",
        payload: payload
      }
      |> Notifications.create_notification_history()

      {:noreply, :event_handled}
    else
      err ->
        log_sentry_error(err)
    end
  end

  @spec log_sentry_error(term) :: Sentry.send_result()
  def log_sentry_error(error) do
    case error do
      {:error, %Jason.DecodeError{} = err} ->
        Sentry.capture_message("Cambiatus.DbListener Decoding Error", %{extra: err})

      error ->
        Sentry.capture_message("Uknown Cambiatus.DbListener Error", error)
    end

    {:noreply, :error_handled}
  end

  defp format_record(struct, %{created_at: created_at} = record) do
    {:ok, formatted_datetime, _offset} =
      (created_at <> "Z")
      |> DateTime.from_iso8601()

    new_record =
      struct
      |> struct(%{record | created_at: formatted_datetime})

    {:ok, new_record}
  end
end
