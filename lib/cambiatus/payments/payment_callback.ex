defmodule Cambiatus.Payments.PaymentCallback do
  @moduledoc """
  Ecto model that holds external services callbacks

  Those callbacks may change the status of their origin entity, could be a shop buy or a community contribution, or other source.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "payment_callbacks" do
    field(:payload, :map)
    field(:payment_method, Ecto.Enum, values: [:paypal, :bitcoin, :ethereum, :eos])
    field(:status, :string)
    field(:external_id, :string)

    timestamps()
  end

  @required_fields ~w(payload payment_method status external_id)a
  @optional_fields ~w()a

  def changeset(%__MODULE__{} = callback, params) do
    callback
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
