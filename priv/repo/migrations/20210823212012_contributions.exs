defmodule Cambiatus.Repo.Migrations.Contributions do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE currency As ENUM ('USD', 'BRL', 'CRC', 'BTC', 'ETH', 'EOS')")

    execute("CREATE TYPE payment_method As ENUM ('paypal', 'bitcoin', 'ethereum', 'eos')")

    execute(
      "CREATE TYPE contribution_status As ENUM ('created', 'captured', 'approved', 'rejected', 'failed')"
    )

    create table(:contributions, primary_key: false) do
      add(:id, :uuid,
        primary_key: true,
        comment:
          "ID representing the contribution. Its an UUID to make sure its unique across our envs"
      )

      add(:community_id, references(:communities, column: :symbol, type: :string), null: false)
      add(:user_id, references(:users, column: :account, type: :string), null: false)

      add(:amount, :float,
        null: false,
        comment:
          "Amount of the contribution, since we support multiple currencies, we use a float point."
      )

      add(:currency, :currency,
        default: "USD",
        null: false,
        comment: "Typed currency, using ISO format"
      )

      add(:payment_method, :payment_method,
        default: "paypal",
        null: false,
        comment: "Payment method used, typed with the integrations we got"
      )

      add(:status, :contribution_status,
        default: "created",
        null: false,
        comment:
          "Internal status of the transaction to our system, may not represent outside state"
      )

      add(:external_id, :string,
        null: true,
        comment: "Indexed external ID to help track the contribution in our frontends"
      )

      timestamps()
    end
  end

  def down do
    drop(table(:contributions))

    execute("DROP TYPE currency")
    execute("DROP TYPE payment_method")
    execute("DROP TYPE contribution_status")
  end
end
