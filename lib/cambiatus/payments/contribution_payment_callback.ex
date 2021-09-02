defmodule Cambiatus.Payments.ContributionPaymentCallback do
  use Ecto.Schema

  alias Cambiatus.Payments.{Contribution, PaymentCallback}

  @primary_key false
  @foreign_key_type :binary_id

  schema "contributions_payment_callbacks" do
    belongs_to(:contribution, Contribution, primary_key: true)
    belongs_to(:payment_callback, PaymentCallback, primary_key: true)

    timestamps()
  end
end
