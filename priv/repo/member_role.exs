IO.puts("Filling member_roles table with default values")

alias Cambiatus.Repo
alias Cambiatus.Commune.{Community, NetworkRole, Role}

# TODO: REMOVE THIS
Repo.delete_all(Role)

if Repo.aggregate(Role, :count, :id) > 0 do
  IO.puts("Roles already migrated")
else
  Community
  |> Repo.all()
  |> Enum.map(fn community ->
    {:ok, role} =
      %Role{}
      |> Role.changeset(%{
        name: "member",
        permissions: [:invite, :claim, :order, :sell],
        community_id: community.symbol
      })
      |> Repo.insert()

    community = Repo.preload(community, :members)

    Enum.map(community.network, fn member_link ->
      %NetworkRole{}
      |> NetworkRole.changeset(%{role_id: role.id, network_id: member_link.id})
      |> Repo.insert!()
    end)
  end)
end
