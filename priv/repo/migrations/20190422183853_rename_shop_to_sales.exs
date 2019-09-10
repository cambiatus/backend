defmodule BeSpiral.Repo.Migrations.RenameShopToSales do
  @moduledoc """
  Migration to rename the shop table to sales
  """
  use Ecto.Migration

  def change do
    rename(table(:shop), to: table(:sales))
  end
end
