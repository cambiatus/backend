defmodule Cambiatus.Kyc.Country do
  @moduledoc """
  Country Ecto Model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Kyc.State

  schema "countries" do
    field(:name, :string)

    has_many(:states, State)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w()a

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> unique_constraint(:name)
  end
end
