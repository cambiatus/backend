defmodule BeSpiral.Notifications.PushSubscription do
  @moduledoc """
  Push Subscription object data structure
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias BeSpiral.{
    Accounts.User,
    Notifications.PushSubscription
  }

  @type t :: %__MODULE__{}

  schema "push_subscriptions" do
    field(:endpoint, :string)
    field(:auth_key, :string)
    field(:p_key, :string)
    belongs_to(:account, User, references: :account, type: :string)
  end

  @fields ~w(endpoint auth_key p_key)a

  @doc """
  Builds a changeset for push subscriptions 
  """
  @spec changeset(PushSubscription.t(), map()) :: Ecto.Changeset.t()
  def changeset(%PushSubscription{} = push_sub, attrs) do
    push_sub
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  @doc """
  Associates a user to a new push subscription 
  """
  @spec create_changeset(map(), map()) :: Ecto.Changeset.t()
  def create_changeset(%User{} = usr, params) do
    %PushSubscription{}
    |> changeset(params)
    |> put_assoc(:account, usr)
  end
end
