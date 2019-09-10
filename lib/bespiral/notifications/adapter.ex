defmodule BeSpiral.Notifications.Adapter do
  @moduledoc """
  Behaviour to use when implementing the web push adapter
  """
  alias BeSpiral.{
    Notifications.PushSubscription
  }

  @doc """
  A call back to handle sending a web push notification request
  """
  @callback send_web_push(map(), PushSubscription.t()) :: {:ok, term()} | {:error, term()}
end
