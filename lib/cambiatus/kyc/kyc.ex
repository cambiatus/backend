defmodule Cambiatus.Kyc do
  @moduledoc """
  KYC Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User

  schema "kyc" do
    # TODO: validate user_type
    field(:user_type, :string)
    field(:document, :string)
    # TODO: validate document_type
    field(:document_type)
    # TODO: validate phone format dependent on country
    field(:phone, :string)
    # TODO: validate country values
    field(:country, :string)
    field(:is_verified, :boolean)

    belongs_to(:account, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(account user_type document document_type phone country is_verified)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
