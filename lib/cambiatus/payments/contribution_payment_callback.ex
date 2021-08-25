defmodule Cambiatus.Payments.ContributionPaymentCallback do
  use Ecto.Schema

  alias Cambiatus.Payments.{Contribution, PaymentCallback}

  schema "contributions_payment_callbacks" do
    belongs_to(:contribution, Contribution)
    belongs_to(:callback, PaymentCallback)

    timestamps()
  end
end
