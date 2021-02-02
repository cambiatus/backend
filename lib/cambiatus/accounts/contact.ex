defmodule Cambiatus.Accounts.Contact do
  @moduledoc """
  Ecto entity to hold contact information
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.{Contact, User}

  schema "contacts" do
    field(:type, Ecto.Enum, values: [:phone, :whatsapp, :telegram, :instagram])
    field(:external_id, :string)

    belongs_to(:user, User, references: :account, type: :string)
    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(user_id type external_id)a

  def changeset(%Contact{} = contact, attrs) do
    contact
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_external_id()
  end

  def validate_external_id(changeset) do
    regex =
      case changeset.params["type"] do
        "phone" ->
          ~r/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/

        "whatsapp" ->
          ~r/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/

        "telegram" ->
          ~r/^(?:https?:)?\/\/(?:t(?:elegram)?\.me|telegram\.org)\/(?P<username>[a-z0-9\_]{5,32})\/?$/


        "instagram" ->
          ~r/^(?:https?:)?\/\/(?:www\.)?(?:instagram\.com|instagr\.am)\/(?P<username>[A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)$/

        _ ->
          ~r/(?s).*/
      end

    validate_format(changeset, :external_id, regex)
  end
end
