defmodule CambiatusWeb.ManifestController do
  use CambiatusWeb, :controller

  alias Cambiatus.Commune

  def get_subdomain(conn) do
    with subdomain <- conn.host do
      {:ok, subdomain}
    else
      nil ->
        subdomain = conn.private.absinthe.context.domain
        {:ok, subdomain}

      _ ->
        {:error, "No subdomain provided"}
    end
  end

  def serve_manifest_json(conn, community) do
    manifest =
      community
      |> manifest_template()
      |> Poison.encode!()

    json(conn, manifest)
  end

  def manifest_template(community) do
    %{
      name: "#{community.name} | Cambiatus",
      short_name: community.name,
      description: community.description,
      start_url: community.website,
      icons: %{src: community.logo, sizes: "144x144", type: "image/png", density: "3.0"},
      display: "standalone"
    }
  end

  def manifest(conn, _params) do
    with {:ok, host} <- get_subdomain(conn),
         {:ok, community} <- Commune.get_community_by_subdomain(host) do
      serve_manifest_json(conn, community)
    else
      # Community not found, use placeholder community
      {:error, _} ->
        community = %{
          name: "Cambiatus",
          description: "Cambiatus description",
          website: "https://www.cambiatus.com/",
          logo: "Cambiatus logo"
        }

        serve_manifest_json(conn, community)

      _ ->
        conn
        |> put_status(422)
        |> json(%{error: "Community is required"})
    end
  end
end
