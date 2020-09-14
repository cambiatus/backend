defmodule Cambiatus.Kyc.Neighborhood do
  @moduledoc """
  Neighborhood Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "neighborhoods" do
    field(:name, :string)
    belongs_to(:city, Cambiatus.Kyc.City)

    timestamps()
  end

  @required_fields ~w(name city_id)a
  @optional_fields ~w()a

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
  end
end
