defmodule CambiatusWeb.ManifestControllerTest do
  use Cambiatus.ApiCase
  use CambiatusWeb.ConnCase

  describe "Manifest" do
    test "get manifest from existing community" do
      # Insert community and assign its domain to the http request
      # using Cambiatus.ApiCase

      community = insert(:community)

      conn = build_conn() |> assign_domain(community.subdomain.name)

      response = get(conn, "/api/manifest")

      %{"short_name" => short_name} = json_response(response, 200)

      # Check http code 200 and if the community name served is the same generated
      assert response.status == 200
      assert short_name == community.name
    end

    test "get manifest from non existing community" do
      # Send conn without subdomain and check for http code 301 and redirect
      conn =
        build_conn()
        |> get("/api/manifest")

      [location] =
        conn
        |> get_resp_header("location")

      assert conn.status == 301
      assert location == "/manifest.json"
    end
  end
end
