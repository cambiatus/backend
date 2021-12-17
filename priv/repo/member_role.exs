IO.puts("Filling member_roles table with default values")

alias Cambiatus.Repo
alias Cambiatus.Commune.{Community, Network, NetworkRoles, Role}

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

    Enum.map(community.members, fn member ->
      member = Repo.preload(:network)
      %NetworkRoles{}
      |> NetworkRoles.changeset()
      |> Network.changeset(%{role_id: role.id})
      # |> Repo.update()
    end)
  end)
end
