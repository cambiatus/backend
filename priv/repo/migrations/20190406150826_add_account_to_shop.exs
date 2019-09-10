defmodule BeSpiral.Repo.Migrations.AddAccountToShop do
  use Ecto.Migration

  def change do
    alter table(:shop) do
      add(:creator_id, references(:users, column: :account, type: :string))
    end
  end
end
