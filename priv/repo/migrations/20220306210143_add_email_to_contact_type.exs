defmodule Cambiatus.Repo.Migrations.AddEmailToContactType do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE contact_type ADD VALUE 'email'")
  end

  def down do
  end
end
