defmodule CambiatusWeb.ManifestController do
  use CambiatusWeb, :controller

  alias Cambiatus.Repo

  def manifest_template(community) do
    %{
      name: "#{community.name} | Cambiatus",
      short_name: community.name,
      description: community.description,
      start_url: community.subdomain.name,
      icons: %{src: community.logo, sizes: "144x144", type: "image/png", density: "3.0"},
      display: "standalone"
    }
  end

  def manifest(conn, _params) do
    context = conn.private[:absinthe][:context]

    case Map.fetch(context, :current_community) do
      {:ok, community} ->
        manifest =
          community
          |> Repo.preload(:subdomain)
          |> manifest_template()

        json(conn, manifest)

      :error ->
        conn
        |> put_status(301)
        |> redirect(to: "/manifest.json")
    end
  end
end
