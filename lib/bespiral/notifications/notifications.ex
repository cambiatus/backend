defmodule BeSpiral.Notifications do
  @moduledoc """
  Context to handle notifications in the BeSpiral Backend 
  """
  alias BeSpiral.{
    Notifications.PushSubscription,
    Notifications.Payload,
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
