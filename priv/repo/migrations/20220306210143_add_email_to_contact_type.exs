defmodule Cambiatus.Repo.Migrations.AddEmailToContactType do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE contact_type ADD VALUE 'email'")
  end

  def down do
  end
end
