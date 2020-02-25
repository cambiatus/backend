defmodule Cambiatus.Repo.Migrations.BlockchainTimestampsSaleHistory do
  use Ecto.Migration

  def change do
    alter table(:sale_history) do
      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end
  end
end
