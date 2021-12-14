defmodule Cambiatus.Notifications do
  @moduledoc """
  Context to handle notifications in the Cambiatus Backend
  """

  import Ecto.Query

  alias Cambiatus.{Accounts.User, Commune.Mint, Objectives, Repo}
  alias Cambiatus.Notifications.{PushSubscription, Payload, NotificationHistory}

  @valid_types ~w(transfer verification mint)a

  @doc """
  Adds a push subscription to the database for a user
  """
  @spec add_push_subscription(map(), map()) ::
          {:ok, PushSubscription.t()} | {:error, Ecto.Changeset.t()}
  def add_push_subscription(%User{} = user, params) do
    user
    |> PushSubscription.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Sends a notification to a given subscription.
  Parameters
  * a payload comprising of the title of the notification and body message that will be displayed as notification to client.
  * a push subscription with which to use to send the data.
  """
  @spec send_push(map(), PushSubscription.t()) :: {:ok, term()} | {:error, term()}
  def send_push(%{title: _, body: _, type: type} = attrs, %PushSubscription{} = sub)
      when type in @valid_types do
    sub_attrs = %{
      endpoint: sub.endpoint,
      keys: %{auth: sub.auth_key, p256dh: sub.p_key}
    }

    Payload
    |> struct(attrs)
    |> Payload.serialize()
    |> adapter().send_web_push(sub_attrs)
  end

  def send_push(attrs, _) do
    message = """
    #{inspect(attrs)} is expected contain title, body and a type.
    the `type` should be among #{inspect(@valid_types)}
    """

    {:error, message}
  end

  @doc """
  Collects a users push subscriptions
  """
  @spec get_subscriptions(map()) :: {:ok, list()}
  def get_subscriptions(%User{} = user) do
    loaded_user =
      user
      |> Repo.preload([:push_subscriptions])

    {:ok, loaded_user.push_subscriptions}
  end

  @spec create_notification_history(map()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_notification_history(attrs) do
    %NotificationHistory{}
    |> NotificationHistory.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_user_notification_history(User.t()) :: {:ok, list(Ecto.Schama.t())}
  def get_user_notification_history(%{account: account}) do
    query =
      NotificationHistory
      |> where([n], n.recipient_id == ^account)
      |> order_by([n], desc: n.inserted_at)

    {:ok, Repo.all(query)}
  end

  @doc """
  Notifies an action's validators of a claim that they need to verify

  ## Parameters
  * action: The action whose validators should be notified of the incoming claim
  """
  @spec notify_validators(Action.t()) :: {:ok, atom()} | {:error, term}
  def notify_validators(action) do
    loaded_action =
      action
      |> Repo.preload(:validators)

    # Task analyse the responses from sending out validations and perhaps
    # Modify the returned result
    _ =
      loaded_action.validators
      |> Enum.map(fn v ->
        notify(
          %{
            title: "Claim Verification Request",
            body: action.description,
            type: :verification
          },
          v
        )
      end)

    {:ok, :notified}
  end

  @doc """
  Notifies a Claimer of a check their claim has recieved

  ## Parameters
  * claim: The claim whose claimer should be notified of the incoming check
  """
  @spec notify_claimer(Claim.t()) :: {:ok, atom()} | {:error, term}
  def notify_claimer(claim) do
    loaded_claim =
      claim
      |> Repo.preload([:claimer, :action])

    # Task analyse the responses from sending out notifications
    _ =
      notify(
        %{
          title: "Your claim has received a validation",
          body: loaded_claim.action.description,
          type: :validation
        },
        loaded_claim.claimer
      )

    {:ok, :notified}
  end

  @doc """
  Notifies a Claimer when their claim is approved

  ## Parameters:
  * claim_id: id  of the claim that has just been verified
  """
  @spec notify_claim_approved(integer()) :: {:ok, atom()} | {:error, term}
  def notify_claim_approved(claim_id) do
    case Objectives.get_claim(claim_id) do
      {:ok, claim} ->
        loaded_claim =
          claim
          |> Repo.preload([:action, :claimer])

        _ =
          notify(
            %{
              title: "Your claim has been approved",
              body: loaded_claim.action.description,
              type: :validation
            },
            loaded_claim.claimer
          )

        {:ok, :notified}

      error ->
        {:error, error}
    end
  end

  @doc """
  Notifies a reciever of a mint whenever some currency is issued to them


  ## Parameters:
  * mint: The mint record of the issue in question
  """
  @spec notify_mintee(Mint.t()) :: {:ok, atom()} | {:error, term}
  def notify_mintee(mint) do
    loaded_mint =
      mint
      |> Repo.preload([:to, :community])

    _ =
      notify(
        %{
          title: "You have received an issue",
          body:
            "#{loaded_mint.quantity}#{loaded_mint.community.symbol} has been issued to your account",
          type: :mint
        },
        loaded_mint.to
      )

    {:ok, :notified}
  end

  @doc """
  Update the number of unread notifications for a user whenever their notificatios are updated

  ## Parameters
  * account: The user whose unread notifications we are updating at the moment
  """
  @spec update_unread(String.t()) :: :ok | {:error, term}
  def update_unread(acct) do
    {:ok, payload} =
      acct
      |> get_unread()

    Absinthe.Subscription.publish(CambiatusWeb.Endpoint, payload, unreads: acct)
  end

  @doc """
  Collects unread notifications metadata for a user

  ## Parameters
  * account: account name of the user in question
  """
  @spec get_unread(String.t()) :: {:ok, map()} | {:error, term}
  def get_unread(acc) do
    query =
      from(n in NotificationHistory,
        where: n.recipient_id == ^acc and n.is_read == false
      )

    items = Repo.all(query)

    case items do
      [] ->
        {:ok, %{unreads: 0}}

      vals ->
        {:ok, %{unreads: Enum.count(vals)}}
    end
  end

  @doc """
  Collects a notification history object

  ## Parameters
  * id: id of the notification
  """
  @spec get_notification_history(User.t(), integer()) ::
          {:ok, NotificationHistory.t()} | {:error, String.t()}
  def get_notification_history(current_user, id) do
    case Repo.get(NotificationHistory, id) do
      nil ->
        {:error, "NotificationHistory with id: #{id} not found"}

      notification ->
        if notification.recipient_id == current_user.account do
          {:ok, notification}
        else
          {:error, "Unauthorized"}
        end
    end
  end

  @doc """
  Flags a notification history as read

  ## Parameters
  * notification: the instance of notification history
  """
  @spec mark_as_read(NotificationHistory.t()) :: {:ok, map()} | {:error, term}
  def mark_as_read(notification) do
    notification
    |> NotificationHistory.flag_as_read()
    |> Repo.update()
  end

  @doc false
  defp adapter do
    Application.get_env(:cambiatus, __MODULE__)[:adapter]
  end

  @doc false
  defp notify(payload, user) do
    {:ok, subs} = get_subscriptions(user)

    subs
    |> Enum.map(fn sub ->
      send_push(payload, sub)
    end)
  end
end
