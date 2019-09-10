defmodule BeSpiral.Notifications.Payload do
  @moduledoc """
  Represents a web push payload consisting of the various items needed
  to make the message to be delivered via the push subscription.

  The datastructure is comprised of a number of elements

  1. `title` - This is the notification title and will be the most prominently displayed information on the
  notification it should be 30 characters or less 

  2. `body` - This is the body of the notification, this will usually be displayed when the notification is expanded 
  use this as a call to action to inform the user what to do about the notification 

  3. `type` - This will be enumerated type based on all the notifications we have, this will be used to inform the 
  frontend what actions it should display for the notification and how to handle those actions
  """

  @enforce_keys ~w(title body type)a
  defstruct title: "Bespiral", body: "", type: ""

  @type t :: %__MODULE__{
          title: String.t(),
          body: String.t(),
          type: String.t()
        }

  @doc """
  Serializes the provided payload into a json string for the client.
  """
  @spec serialize(Payload.t()) :: {:ok, any()} | {:error, atom()} | no_return
  def serialize(%__MODULE__{} = payload) do
    payload
    |> Map.from_struct()
    |> Jason.encode!()
  end
end
