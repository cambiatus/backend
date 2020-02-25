defmodule Cambiatus.Repo.Migrations.RemoveBuyOptionFromSales do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      remove :is_buy
    end
  end
end
