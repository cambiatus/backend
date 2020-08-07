defmodule Cambiatus.Kyc.City do
  @moduledoc """
  City Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "cities" do
    field(:name, :string)
    belongs_to(:state, Cambiatus.Kyc.State)

    timestamps()
  end

  @required_fields ~w(name state_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
