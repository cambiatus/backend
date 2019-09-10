defmodule BeSpiral.Repo.Migrations.RenameSaleHistoryColumnTo do
  use Ecto.Migration

  def change do
    rename(table(:sale_history), :to, to: :to_id)
  end
end
