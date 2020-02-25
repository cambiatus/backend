defmodule Cambiatus.Repo.Migrations.ModifyActions do
  @moduledoc """
  Migration to update actions field according to smart contract
  """
  use Ecto.Migration

  def change do
    rename(table(:actions), :community_objective_id, to: :objective_id)

    alter table(:actions) do
      add(:deadline, :utc_datetime)
      add(:usages, :integer)
      add(:usages_left, :integer)
      add(:verifications, :integer)
      add(:verification_type, :string)
      add(:is_completed, :boolean)
      remove(:is_verified)
    end
  end
end
