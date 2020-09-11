defmodule Cambiatus.Kyc.City do
  @moduledoc """
  City Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Kyc.{
    State,
    Neighborhood
  }

  schema "cities" do
    field(:name, :string)
    belongs_to(:state, State)
    has_many(:neighborhoods, Neighborhood)

    timestamps()
  end

  @required_fields ~w(name state_id)a
  @optional_fields ~w()a

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:neighborhoods)
  end
end
