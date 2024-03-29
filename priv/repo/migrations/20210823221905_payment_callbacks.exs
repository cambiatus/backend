defmodule Cambiatus.Repo.Migrations.PaymentCallbacks do
  use Ecto.Migration

  def change do
    create table(:payment_callbacks) do
      add(:payload, :map,
        null: false,
        comment: "Payload received from external service as a callback"
      )

      add(:processed, :boolean,
        default: false,
        null: false,
        comment: "Flag that informs if the callback was already processed by the system"
      )

      timestamps()
    end

    create table(:contributions_payment_callbacks) do
      add(:contribution_id, references(:contributions, type: :uuid))
      add(:payment_callback_id, references(:payment_callbacks))

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
