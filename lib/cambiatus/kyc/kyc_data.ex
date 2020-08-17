defmodule Cambiatus.Kyc.KycData do
  @moduledoc """
  KYC Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.{Accounts.User, Kyc.Country, Repo}

  schema "kyc_data" do
    field(:user_type, :string)
    field(:document, :string)
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
    |> validate_required(@required_fields)
    |> validate_user_type()
    |> validate_document_type()
    |> validate_format(:phone, ~r/[1-9]{1}\d{3}-?\d{4}/)
    |> validate_document()
  end

  def validate_user_type(changeset) do
    if Enum.any?(["natural", "juridical"], &(&1 == get_field(changeset, :user_type))) do
      changeset
    else
      add_error(changeset, :user_type, "is invalid")
    end
  end

  def validate_document_type(changeset) do
    if Enum.any?(
         ["mipyme", "gran_empresa", "cedula_de_identidad", "dimex", "nite"],
         &(&1 == get_field(changeset, :document_type))
       ) do
      changeset
    else
      add_error(changeset, :document_type, "is invalid")
    end
  end

  @doc """
  This function validates documents that follow the Costa Rica's standard

  Reference: https://help.hulipractice.com/es/articles/1348413-ingresar-informacion-de-emisores-solo-para-costa-rica
  """
  def validate_document(%{valid?: false} = changeset), do: changeset

  def validate_document(changeset) do
    user_type = get_field(changeset, :user_type)

    changeset
    |> validate_document_by_user_type(user_type)
    |> validate_document_by_document_type()
  end

  defp validate_document_by_user_type(changeset, "natural") do
    document_type = get_field(changeset, :document_type)
    natural_documents = ["cedula_de_identidad", "dimex", "nite"]

    if Enum.any?(natural_documents, &(&1 == document_type)) do
      changeset
    else
      add_error(changeset, :document_type, "is not valid for 'natural' user_type")
    end
  end

  defp validate_document_by_user_type(changeset, "juridical") do
    document_type = get_field(changeset, :document_type)
    juridical_documents = ["mipyme", "gran_empresa"]

    if Enum.any?(juridical_documents, &(&1 == document_type)) do
      changeset
    else
      add_error(changeset, :document_type, "is not valid for 'juridical' user_type")
    end
  end

  def validate_document_by_document_type(changeset) do
    document_type = get_field(changeset, :document_type)
    document = get_field(changeset, :document)
    regex = get_document_type_regex(document_type)

    if String.match?(document, regex) do
      changeset
    else
      add_error(changeset, :document, "is invalid for #{document_type}")
    end
  end

  defp get_document_type_regex(document_type) do
    case document_type do
      "cedula_de_identidad" ->
        ~r/^[1-9]-?\d{4}-?\d{4}$/

      "dimex" ->
        ~r/[1-9]{1}\d{10-11}/

      "nite" ->
        ~r/[1-9]{1}\d{9}/

      "mipyme" ->
        ~r/\d-?\d{3}-?\d{6}/

      "gran_empresa" ->
        ~r/\d-?\d{3}-?\d{6}/
    end
  end
end
