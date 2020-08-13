defmodule Cambiatus.Kyc do
  @moduledoc """
  KYC Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.{Accounts.User, Kyc.Country, Repo}

  schema "kyc" do
    field(:user_type, :string)
    field(:document, :string)
    # TODO: validate documents
    field(:document_type)
    field(:phone, :string)
    field(:is_verified, :boolean)

    belongs_to(:account, User, references: :account, type: :string)
    belongs_to(:country, Country)

    timestamps()
  end

  @required_fields ~w(account_id user_type document document_type phone country_id)a
  @optional_fields ~w(is_verified)

  def changeset(model, params \\ :empty) do
    model
    |> Repo.preload(:country)
    |> Repo.preload(:account)
    |> cast(params, @required_fields, @optional_fields)
    |> validate_user_type()
    |> validate_document_type()
    |> validate_format(:phone, ~r/\[1-9]{1}[0-9]{3,14}/)
  end

  def validate_user_type(changeset) do
    unless Enum.any?(["natural", "juridical"], &(&1 == get_field(changeset, :user_type))) do
      add_error(changeset, :user_type, "is invalid")
    else
      changeset
    end
  end

  def validate_document_type(changeset) do
    unless Enum.any?(
             ["mipyme", "gran_empresa", "cedula_de_identidad", "dimex", "nite"],
             &(&1 == get_field(changeset, :document_type))
           ) do
      add_error(changeset, :document_type, "is invalid")
    else
      changeset
    end
  end
end
