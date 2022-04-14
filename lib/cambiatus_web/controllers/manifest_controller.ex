defmodule CambiatusWeb.ManifestController do
  use CambiatusWeb, :controller

  alias Cambiatus.Commune

  def get_subdomain(conn) do
      subdomain  = conn
      |> Map.get(:private)
      |> Map.get(:absinthe)
      |> Map.get(:context)
      |> Map.get(:domain)

    case subdomain do
      nil ->
        {:error, "No subdomain provided"}
      _ ->
        {:ok, subdomain}
    end

  end

  def manifest_template({:ok, community}) do
    %{
      name:  "#{community.name} | Cambiatus",
      short_name: community.name,
      description: community.description,
      start_url: community.website,
      icons: %{ src: community.logo, sizes: "144x144", type: "image/png", density: "3.0"},
      display: "standalone"
    }
  end

  def manifest(conn, _params) do

    with {:ok, community: community} <- get_subdomain(conn) do

      manifest = community
      |> Commune.get_community_by_subdomain()
      |> manifest_template()
      |> Poison.encode!()

      json(conn, manifest)
    else
      _ ->
        conn
        |> put_status(422)
        |> json(%{error: "Community is required"})
    end

  end

end
