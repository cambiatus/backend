defmodule Cambiatus.Repo.Migrations.CleanProductsBlockchainData do
  use Ecto.Migration

  def change do
    alter table(:products) do
      remove(:image)
      remove(:created_block)
      remove(:created_tx)
      remove(:created_eos_account)
      remove(:created_at)
    end
  end
end
