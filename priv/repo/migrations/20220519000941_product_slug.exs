defmodule Cambiatus.Repo.Migrations.ProductSlug do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add(:position, :integer, comment: "Optional field used to order products")
    end
  end
end
