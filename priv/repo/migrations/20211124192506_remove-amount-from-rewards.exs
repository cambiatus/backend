defmodule :"Elixir.Cambiatus.Repo.Migrations.Remove-amount-from-rewards" do
  use Ecto.Migration

  def change do
    alter table(:rewards) do
      remove(:amount)
    end
  end
end
