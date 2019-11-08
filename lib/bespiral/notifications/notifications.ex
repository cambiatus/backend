defmodule BeSpiral.Notifications do
  @moduledoc """
  Context to handle notifications in the BeSpiral Backend
  """

  import Ecto.Query

  alias BeSpiral.{
    Commune,
    Notifications.PushSubscription,
    Notifications.Payload,
    Notifications.NotificationHistory,
    Accounts.User,
    Repo
  }

  @valid_types ~w(transfer verification)a

  @doc """
  Adds a push subscription to the database for a user
  """
  @spec add_push_subscription(map(), map()) ::
          {:ok, PushSubscription.t()} | {:error, Ecto.Changeset.t()}
  def add_push_subscription(%User{} = usr, params) do
    usr
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

  @spec get_user_notification_history(binary()) :: {:ok, list(Ecto.Schama.t())}
  def get_user_notification_history(user) do
    query =
      NotificationHistory
      |> where([n], n.recipient_id == ^user)
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
      |> Repo.preload(validators: [:validator])

    # Task analyse the responses from sending out validations and perhaps
    # Modify the returned result
    _ =
      loaded_action.validators
      |> Enum.map(fn v ->
        notify(
          %{title: "Claim Verification Request", body: action.description, type: :verification},
          v.validator
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
  Update the number of unread notifications for a user whenever their notificatios are updated 

  ## Parameters 
  * account: The user whose unread notifications we are updating at the moment
  """
  @spec update_unread(String.t()) :: :ok | {:error, term}
  def update_unread(acct) do
    {:ok, payload} =
      acct
      |> get_unread()

    Absinthe.Subscription.publish(Endpoint, payload, unreads: acct)
  end

  @doc """
  Notifies a Claimer when their claim is approved 

  ## Parameters: 
  * claim_id: id  of the claim that has just been verified
  """
  @spec notify_claim_approved(integer()) :: {:ok, atom()} | {:error, term}
  def notify_claim_approved(claim_id) do
    with {:ok, claim} <- Commune.get_claim(claim_id) do
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
    else
      v ->
        {:error, v}
    end
  end

  @doc """
  Collects unread notifications metadata for a user

  ## Parameters 
  * account: account name of the user in question
  """
  @spec get_unread(String.t()) :: {:ok, map()} | {:error, term}
  def get_unread(acc) do
    items =
      from(n in NotificationHistory, where: n.recipient_id == ^acc and n.is_read == false)
      |> Repo.all()

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
  @spec get_notification_history(integer()) ::
          {:ok, NotificationHistory.t()} | {:error, String.t()}
  def get_notification_history(id) do
    case Repo.get(NotificationHistory, id) do
      nil ->
        {:error, "NotificationHistory with id: #{id} not found"}

      val ->
        {:ok, val}
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
    Application.get_env(:bespiral, __MODULE__)[:adapter]
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
