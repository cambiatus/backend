defmodule Cambiatus.Kyc.State do
  @moduledoc """
  State Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "states" do
    field(:name, :string)
    belongs_to(:country, Cambiatus.Kyc.Country)

    timestamps()
  end

  @required_fields ~w(name country_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
