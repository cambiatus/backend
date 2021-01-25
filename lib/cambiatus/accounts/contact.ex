defmodule Cambiatus.Accounts.Contact do
  @moduledoc """
  Ecto entity to hold contact information
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.{Contact, User}

  schema "contacts" do
    field(:type, Ecto.Enum, values: [:phone, :whatsapp, :telegram, :signal, :instagram])
    field(:external_id, :string)

    belongs_to(:user, User, references: :account, type: :string)
    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(user_id type external_id)a

  def changeset(%Contact{} = contact, attrs) do
    contact
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
