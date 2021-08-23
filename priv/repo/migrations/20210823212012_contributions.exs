defmodule Cambiatus.Repo.Migrations.Contributions do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE currency As ENUM ('USD', 'BRL', 'CRC', 'BTC', 'ETH', 'EOS')")

    execute("CREATE TYPE payment_method As ENUM ('paypal', 'bitcoin', 'ethereum', 'eos')")

    execute(
      "CREATE TYPE contribution_status As ENUM ('created', 'captured', 'approved', 'rejected', 'failed')"
    )

    create table(:contributions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:account_id, references(:users, column: :account, type: :string))
      add(:amount, :float)
      add(:currency, :currency, default: "USD")
      add(:payment_method, :payment_method, default: "paypal")
      add(:status, :contribution_status, default: "created")

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
