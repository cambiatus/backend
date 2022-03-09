defmodule Cambiatus.Repo.Migrations.ImproveNetworkRoleConsistency do
  use Ecto.Migration

  def change do
    alter table(:network_roles) do
      modify(:network_id, references(:network),
        null: false,
        from: references(:network),
        comment:
          "Reference to network, which contains a relation between the user and the community"
      )

      modify(:role_id, references(:roles),
        null: false,
        from: references(:roles),
        comment: "Reference to role, that contains the community and the permissions"
      )
    end

    create(unique_index(:network_roles, [:network_id, :role_id]))
  end
end
