defmodule Cambiatus.Repo.Migrations.AddLinkToContactType do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE contact_type ADD VALUE 'link'")
  end

  def down do
  end
end
