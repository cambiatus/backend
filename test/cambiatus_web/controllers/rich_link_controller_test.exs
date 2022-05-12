defmodule CambiatusWeb.RichLinkControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Repo

  @rich_link_file Path.expand("../../../lib/cambiatus_web/templates/rich_link.html.eex", __DIR__)

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "RichLink" do
    test "generate rich link for community",
         %{conn: conn} do
      # Get community for DataCase.valid_community_and_user,
      # pattern match community for name and subdomain,
      # insert subdomain name into conn
      community =
        insert(:community)
        |> Repo.preload(:subdomain)

      data = %{
        name: community.name,
        description: community.description,
        title: community.name,
        url: community.subdomain.name,
        image: community.logo,
        locale: nil
      }

      expected_response =
        %{data | description: md_to_txt(data.description)}
        |> Enum.into([])

      conn =
        %{conn | host: community.subdomain.name}
        |> get("/api/rich_link")

      response = html_response(conn, 200)

      # Check http code 200 and if the community name served is the same generated
      assert conn.status == 200
      assert EEx.eval_file(@rich_link_file, expected_response) == response
    end

    test "generate rich link for user",
         %{conn: conn} do
      # Get community for DataCase.valid_community_and_user,
      # pattern match community for name and subdomain,
      # insert subdomain name into conn
      #  community = Repo.preload(community, :subdomain)

      user = insert(:user)

      data = %{
        name: user.name,
        description: user.bio,
        title: user.name,
        url: user.email,
        image: user.avatar,
        locale: user.location
      }

      expected_response =
        %{data | description: md_to_txt(data.description)}
        |> Enum.into([])

      conn = get(conn, "/api/rich_link/profile/#{user.account}")

      response = html_response(conn, 200)

      # Check http code 200 and if the community name served is the same generated
      assert conn.status == 200
      assert EEx.eval_file(@rich_link_file, expected_response) == response
    end

    test "generate rich link for product",
         %{conn: conn} do
      # Get community for DataCase.valid_community_and_user,
      # pattern match community for name and subdomain,
      # insert subdomain name into conn
      product =
        insert(:product)
        |> Repo.preload(:images)

      [image | _] = product.images

      data = %{
        name: product.title,
        description: product.description,
        title: product.title,
        url: nil,
        image: image.uri,
        locale: nil
      }

      expected_response =
        %{data | description: md_to_txt(data.description)}
        |> Enum.into([])

      conn = get(conn, "/api/rich_link/shop?id=#{product.id}")

      response = html_response(conn, 200)

      # Check http code 200 and if the community name served is the same generated
      assert conn.status == 200
      assert EEx.eval_file(@rich_link_file, expected_response) == response
    end
  end

  defp md_to_txt(markdown) do
    with {:ok, string, _} <- Earmark.as_html(markdown) do
      HtmlSanitizeEx.strip_tags(string)
      |> String.trim()
    else
      {:error, _} ->
        ""
    end
  end
end
