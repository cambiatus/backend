defmodule CambiatusWeb.ManifestControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Manifest" do
    setup :valid_community_and_user

    test "get manifest from existing community",
         %{conn: conn} do
      # Generate community, save name and subdomain name
      # insert subdomain name into conn
      community = insert(:community)
      subdomain = community.subdomain.name
      name = community.name
      conn = %{conn | host: subdomain}

      conn = get(conn, "/api/manifest")

      response = conn.resp_body
      {:ok, response} = Poison.decode(response)
      {:ok, response} = Poison.decode(response, keys: :atoms)

      # Check http code 200 and if the community name served is the same generated
      assert conn.status == 200
      assert name == response.short_name
    end

    test "get manifest from non existing community",
         %{conn: conn} do
      # Send conn without subdomain and check for http code 301
      conn = %{conn | host: nil}
      conn = get(conn, "/api/manifest")

      assert conn.status == 301
    end
  end
end
