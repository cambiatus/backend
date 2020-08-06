defmodule Cambiatus.Kyc.Address do
  @moduledoc """
  Address Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User

  schema "addresses" do
    # TODO: Validate country to be only the ones we support
    field(:country, :string)
    field(:street, :string)
    field(:neighborhood, :string)
    field(:city, :string)
    field(:state, :string)
    # TODO: Validate zip according to country
    field(:zip, :string)
    field(:number, :string)

    belongs_to(:account, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(account)
  @optional_fields ~w(country street neighborhood city state zip number)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
