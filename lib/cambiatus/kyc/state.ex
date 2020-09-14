defmodule Cambiatus.Kyc.State do
  @moduledoc """
  State Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Kyc.{
    Country,
    City
  }

  schema "states" do
    field(:name, :string)
    belongs_to(:country, Country)
    has_many(:cities, City)

    timestamps()
  end

  @required_fields ~w(name country_id)a
  @optional_fields ~w()a

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
  end
end
