defmodule Cambiatus.Notifications.NotificationHistory do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  @type t :: %__MODULE__{}

  alias Cambiatus.{Accounts.User, Notifications.NotificationHistory}

  schema "notification_history" do
    belongs_to(:recipient, User, references: :account, type: :string)
    field(:type, :string)
    field(:payload, :string)
    field(:is_read, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(recipient_id type payload)a

  @spec changeset(NotificationHistory.t(), map()) :: Ecto.Changeset.t()
  def changeset(%NotificationHistory{} = notification, attrs) do
    notification
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, ["sale", "transfer", "sale_history", "claim", "verification"])
  end

  def create_changeset(attrs) do
    %NotificationHistory{}
    |> changeset(attrs)
    |> put_assoc(:recipient, attrs.creator)
    |> foreign_key_constraint(:recipient_id)
  end

  @spec flag_as_read(NotificationHistory.t()) :: Ecto.Changeset.t()
  def flag_as_read(notification) do
    notification
    |> changeset(%{})
    |> put_change(:is_read, true)
  end
end
