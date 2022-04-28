defmodule CambiatusWeb.ManifestController do
  use CambiatusWeb, :controller

  alias Cambiatus.Commune

  def get_subdomain(conn) do
    case conn.host do
      subdomain when is_binary(subdomain) ->
        {:ok, subdomain}

      _ ->
        {:error, "No subdomain provided"}
    end
  end

  def manifest_template(community) do
    %{
      name: "#{community.name} | Cambiatus",
      short_name: community.name,
      description: community.description,
      start_url: community.subdomain,
      icons: %{src: community.logo, sizes: "144x144", type: "image/png", density: "3.0"},
      display: "standalone"
    }
  end

  def manifest(conn, _params) do
    with {:ok, host} <- get_subdomain(conn),
         {:ok, community} <- Commune.get_community_by_subdomain(host) do
      manifest =
        community
        |> manifest_template()
        |> Poison.encode!()

      json(conn, manifest)
    else
      _ ->
        conn
        |> put_status(301)
    end
  end
end
