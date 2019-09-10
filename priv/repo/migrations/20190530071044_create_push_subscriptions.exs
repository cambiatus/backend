defmodule BeSpiral.Repo.Migrations.CreatePushSubscriptions do
  @moduledoc """
  Migration for push subscription objects that belong to a user account
  """
  use Ecto.Migration

  def change do
    create table(:push_subscriptions) do
      add(:endpoint, :string)
      add(:auth_key, :string)
      add(:p_key, :string)

      add(
        :account_id,
        references(:users, column: :account, type: :string, on_delete: :delete_all),
        null: false
      )
    end
  end
end
