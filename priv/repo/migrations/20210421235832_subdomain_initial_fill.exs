defmodule Cambiatus.Repo.Migrations.SubdomainInitialFill do
  use Ecto.Migration

  alias Cambiatus.Repo
  alias Cambiatus.Commune.{Community, Subdomain}

  def up do
    Community
    |> Repo.all()
    |> Enum.map(&insert_subdomain/1)
    |> Enum.map(&update_community/1)

    insert_subdomain(%{name: "demo"})
    insert_subdomain(%{name: "staging"})
    insert_subdomain(%{name: "app"})
  end

  def down do
    Repo.delete_all(Subdomain)
  end

  def insert_subdomain(%{name: name} = community) do
    {:ok, subdomain} =
      %Subdomain{}
      |> Subdomain.changeset(%{name: gen_subdomain(name)})
      |> Repo.insert()

    {community, subdomain}
  end

  def update_community({%{name: name} = community, subdomain}) do
    community
    |> Repo.preload(:subdomain)
    |> Community.changeset(%{})
    |> Ecto.Changeset.put_assoc(:subdomain, subdomain)
    |> Repo.update!()
  end

  def gen_subdomain(name) do
    name
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\W/u, "")
    |> String.split(" ")
    |> hd
    |> Kernel.<>(".cambiatus.io")
  end
end
