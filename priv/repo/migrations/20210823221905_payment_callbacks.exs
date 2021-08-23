defmodule Cambiatus.Repo.Migrations.PaymentCallbacks do
  use Ecto.Migration

  def change do
    create table(:payment_callbacks) do
      add(:payload, :map, comment: "Payload received from external service as a callback")

      add(:payment_method, :payment_method,
        default: "paypal",
        comment: "Source that process the payment"
      )

      add(:status, :string, comment: "Status parsed from provider")
      add(:external_id, :string)

      timestamps()
    end

    create table(:contributions_payment_callbacks, primary_key: false) do
      add(:contribution_id, references(:contributions, type: :uuid, primary_key: true))
      add(:payment_callback_id, references(:payment_callbacks, primary_key: true))

      timestamps()
    end

    create(
      unique_index(
        :contributions_payment_callbacks,
        [:contribution_id, :payment_callback_id]
      )
    )
  end
end
