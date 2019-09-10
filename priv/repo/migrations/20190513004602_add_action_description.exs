defmodule BeSpiral.Repo.Migrations.AddActionDescription do
  use Ecto.Migration

  def change do
    alter table(:community_objective_actions) do
      add(:description, :string)
    end
  end
end
