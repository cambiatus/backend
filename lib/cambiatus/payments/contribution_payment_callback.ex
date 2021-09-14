defmodule Cambiatus.Payments.ContributionPaymentCallback do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Payments.{Contribution, PaymentCallback}

  @primary_key false
  schema "contributions_payment_callbacks" do
    belongs_to(:contribution, Contribution, type: :binary_id)
    belongs_to(:payment_callback, PaymentCallback)

    timestamps()
  end

  @required_fields ~w(contribution_id payment_callback_id)a
  @optional_fields ~w()a

  def changeset(contribution_payment_callback, params \\ %{}) do
    contribution_payment_callback
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
