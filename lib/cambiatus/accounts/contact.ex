defmodule Cambiatus.Accounts.Contact do
  @moduledoc """
  Ecto entity to hold contact information
  """

  @default_country_code "US"

  # Regex was inspired by https://github.com/lorey/social-media-profiles-regexs
  @telegram_regex ~r/(?:https?:)?\/\/(?:t(?:elegram)?\.me|telegram\.org)\/(?P<username>[a-z0-9\_]{5,32})\/?/
  @instagram_regex ~r/(?:https?:)?\/\/(?:www\.)?(?:instagram\.com|instagr\.am)\/(?P<username>[A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)/

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.{Contact, User}
  alias ExPhoneNumber

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
    case changeset.changes.type do
      :phone ->
        validate_phone_number(changeset)

      :whatsapp ->
        validate_phone_number(changeset)

      :telegram ->
        validate_format(changeset, :external_id, @telegram_regex)

      :instagram ->
        validate_format(changeset, :external_id, @instagram_regex)

      _ ->
        validate_format(changeset, :external_id, ~r/(?s).*/)
    end
  end

  defp validate_phone_number(changeset, country_code \\ @default_country_code) do
    external_id = changeset.changes.external_id
    {:ok, phone_number} = ExPhoneNumber.parse(external_id, country_code)

    case ExPhoneNumber.is_possible_number?(phone_number) do
      true -> changeset
      false -> add_error(changeset, :external_id, "invalid phone number", additional: "parsed number #{phone_number.national_number}")
    end
  end
end
