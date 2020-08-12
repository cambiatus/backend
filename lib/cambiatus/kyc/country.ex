defmodule Cambiatus.Kyc.Country do
  @moduledoc """
  Country Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field(:name, :string)

    timestamps()
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
  end
end
