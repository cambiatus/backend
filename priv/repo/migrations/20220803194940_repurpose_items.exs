defmodule Cambiatus.Repo.Migrations.RepurposeItems do
  use Ecto.Migration

  def change do
    rename(table(:items), :from_id, to: :seller_id)
    rename(table(:items), :amount, to: :unit_price)

    # TODO: Transfer "to_id" from items table to orders table as buyer_id

    alter table(:items) do
      add(:order_id, references(:orders, on_delete: :delete_all))

      # TODO: Elaborate shipping and status
      add(:shipping, :string, null: true, comment: "This is still a placeholder")

      add(:status, :string,
        null: false,
        default: "Pending confirmation",
        comment: "This is still a placeholder"
      )

      timestamps()
    end
  end
end
