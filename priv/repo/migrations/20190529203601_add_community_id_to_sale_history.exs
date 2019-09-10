defmodule BeSpiral.Repo.Migrations.AddCommunityIdToSaleHistory do
  use Ecto.Migration

  def change do
    rename(table(:sale_history), :quantity, to: :amount)

    alter table(:sale_history) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
    end
  end
end
