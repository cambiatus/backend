defmodule Cambiatus.Repo.Migrations.ChangeHasActionsToHasObjectives do
  use Ecto.Migration

  def change do
    rename(table("communities"), :has_actions, to: :has_objectives)
  end
end
