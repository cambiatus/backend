defmodule BeSpiral.Repo.Migrations.DemuxTables do
  use Ecto.Migration

  def change do
    create table(:_index_state) do
      add(:block_number, :integer, null: false)
      add(:block_hash, :string, null: false)
      add(:is_replay, :boolean, null: false)
    end

    create table(:_block_number_txid, primary_key: false) do
      add(:block_number, :integer, primary_key: true)
      add(:txid, :bigint, null: false)
    end
  end
end
