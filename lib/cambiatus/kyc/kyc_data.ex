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
  @optional_fields ~w(is_verified)a

  def changeset(model, params) do
    model
    |> Repo.preload(:country)
    |> Repo.preload(:account)
    |> cast(params, @required_fields ++ @optional_fields)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:country_id)
    |> validate_required(@required_fields)
    |> validate_user_type()
    |> validate_document_type()
    |> validate_format(:phone, ~r/[1-9]{1}\d{3}-?\d{4}/)
    |> validate_document()
  end

  def validate_user_type(changeset) do
    user_type = get_field(changeset, :user_type)

    if user_type in ["natural", "juridical"] do
      changeset
    else
      add_error(changeset, :user_type, "User type entry is not valid")
    end
  end

  def validate_document_type(changeset) do
    document_type = get_field(changeset, :document_type)

    if document_type in ["mipyme", "gran_empresa", "cedula_de_identidad", "dimex", "nite"] do
      changeset
    else
      add_error(changeset, :document_type, "Document type entry is not valid")
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

    if document_type in natural_documents do
      changeset
    else
      add_error(
        changeset,
        :document_type,
        "Document type entry is not valid for 'natural' user_type"
      )
    end
  end

  defp validate_document_by_user_type(changeset, "juridical") do
    document_type = get_field(changeset, :document_type)
    juridical_documents = ["mipyme", "gran_empresa"]

    if document_type in juridical_documents do
      changeset
    else
      add_error(
        changeset,
        :document_type,
        "Document type entry is not valid for 'juridical' user_type"
      )
    end
  end

  def validate_document_by_document_type(changeset) do
    country_id = get_field(changeset, :country_id)
    %Country{} = country = Repo.get(Country, country_id)

    validate_document_by_document_type(changeset, country.name)
  end

  def validate_document_by_document_type(changeset, "Costa Rica") do
    document_type = get_field(changeset, :document_type)
    document = get_field(changeset, :document)
    pattern = get_document_type_pattern(document_type)

    if String.match?(document, pattern.regex) do
      changeset
    else
      add_error(changeset, :document, document_type_error_handler(document, pattern))
    end
  end

  def validate_document_by_document_type(changeset, _) do
    add_error(changeset, :country_id, "is invalid")
  end

  defp get_document_type_pattern(document_type) do
    case document_type do
      "cedula_de_identidad" ->
        %{
          regex: ~r/^[1-9]-?\d{4}-?\d{4}$/,
          non_null_first_digit: true,
          dashes_positions: [1, 6],
          string_length: [9]
        }

      "dimex" ->
        %{
          regex: ~r/^[1-9]{1}\d{10,11}$/,
          non_null_first_digit: true,
          dashes_positions: [],
          string_length: [12]
        }

      "nite" ->
        %{
          regex: ~r/^[1-9]{1}\d{9}$/,
          non_null_first_digit: true,
          dashes_positions: [],
          string_length: [10]
        }

      "mipyme" ->
        %{
          regex: ~r/^\d-?\d{3}-?\d{6}$/,
          non_null_first_digit: false,
          dashes_positions: [1, 5],
          string_length: [10]
        }

      "gran_empresa" ->
        %{
          regex: ~r/^\d-?\d{3}-?\d{6}$/,
          non_null_first_digit: false,
          dashes_positions: [1, 5],
          string_length: [10]
        }
    end
  end

  def document_type_error_handler(input, opts) do
    message = "The following error(s) were found:\n"
    document_type_error_handler(input, opts, message)
  end

  defp document_type_error_handler(input, %{non_null_first_digit: true} = opts, message) do
    opts = Map.delete(opts, :non_null_first_digit)

    case String.match?(input, ~r/^0/) do
      true ->
        document_type_error_handler(input, opts, message <> "- First digit cannot be zero\n")

      _ ->
        document_type_error_handler(input, opts, message)
    end
  end

  # defp document_type_error_handler(input, %{dahses_positions: [_]} = opts, message) do
  #   case String.match?(input, ~r/^0/) do
  #     true ->
  #       message = message <> "- First digit cannot be zero\n"

  #     _ ->
  #       message = message
  #   end

  #   opts = Map.delete(opts, :dahses_positions)
  #   document_type_error_handler(input, opts, message)
  # end

  defp document_type_error_handler(input, %{string_length: [input_length]} = opts, message) do
    opts = Map.delete(opts, :string_length)
    string = String.replace(input, "-", "")

    case String.length(string) == input_length do
      false ->
        document_type_error_handler(
          input,
          opts,
          message <> "- Entry must contain #{input_length} digits\n"
        )

      _ ->
        document_type_error_handler(input, opts, message)
    end
  end

  defp document_type_error_handler(input, _opts, message) do
    string = String.replace(input, "-", "")

    case String.match?(string, ~r/\D/) do
      true ->
        message <> "- Entry must only contain digits\n"

      _ ->
        message
    end
  end
end
