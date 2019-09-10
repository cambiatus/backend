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

  @valid_types ~w(transfer)a

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

  @doc false
  defp adapter do
    Application.get_env(:bespiral, __MODULE__)[:adapter]
  end
end
