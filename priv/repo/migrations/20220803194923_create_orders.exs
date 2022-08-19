defmodule Cambiatus.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add(:buyer_id, references(:users, column: :account, type: :string))

      add(:payment_method, :payment_method,
        default: "eos",
        null: false,
        comment: "Payment method used, typed with the integrations we got"
      )

      add(:total, :float, comment: "Order total")

      # TODO: Elaborate shipping and status
      add(:status, :string,
        null: false,
        default: "Pending confirmation",
        comment: "This is still a placeholder"
      )

      timestamps()
    end
  end
end
