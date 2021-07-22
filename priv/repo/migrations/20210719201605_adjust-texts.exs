defmodule :"Elixir.Cambiatus.Repo.Migrations.Adjust-texts" do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      modify(:description, :text)
    end

    alter table(:actions) do
      modify(:description, :text)
      modify(:photo_proof_instructions, :text)
    end

    alter table(:objectives) do
      modify(:description, :text)
    end

    alter table(:products) do
      modify(:description, :text)
    end
  end
end
