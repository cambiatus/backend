defmodule Cambiatus.Repo.Migrations.AddClaims do
  @moduledoc """
  Migration to build claims table, used to record a claim by a community member on an
  action they completed
  """
  use Ecto.Migration

  def change do
    create table(:claims) do
      add(:is_verified, :boolean)
      add(:action_id, references(:actions))
      add(:claimer_id, references(:users, column: :account, type: :string))

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create(index(:claims, [:action_id, :claimer_id]))
  end
end
