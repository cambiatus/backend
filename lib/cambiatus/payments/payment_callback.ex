defmodule Cambiatus.Payments.PaymentCallback do
  @moduledoc """
  Ecto model that holds external services callbacks

  Those callbacks may change the status of their origin entity, could be a shop buy or a community contribution, or other source.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "payment_callbacks" do
    field(:payload, :map)
    field(:processed, :boolean, default: false)
    field(:external_id, :string)

    timestamps()
  end

  @required_fields ~w(payload processed)a
  @optional_fields ~w(external_id)a

  def changeset(%__MODULE__{} = callback, params) do
    callback
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
