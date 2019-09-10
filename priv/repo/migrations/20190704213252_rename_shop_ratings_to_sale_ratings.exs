defmodule BeSpiral.Repo.Migrations.RenameShopRatingsToSaleRatings do
  @moduledoc """
  Migration to rename shop_ratings table to sale_ratings
  """

  use Ecto.Migration

  def change do
    rename(table(:shop_ratings), to: table(:sale_ratings))
  end
end
