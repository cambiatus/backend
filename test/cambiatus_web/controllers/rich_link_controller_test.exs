defmodule CambiatusWeb.RichLinkControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Repo

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "RichLink" do
    test "generate rich link for community",
         %{conn: conn} do
      # Insert community and extract data for the rich link
      community =
        insert(:community)
        |> Repo.preload(:subdomain)

      expected_data = %{
        description: md_to_txt(community.description),
        title: community.name,
        url: community.subdomain.name,
        image: community.logo,
        locale: nil
      }

      # Submit GET request for a community rich link
      conn =
        %{conn | host: community.subdomain.name}
        |> get("/api/rich_link")

      response = html_response(conn, 200)

      # Check if all the rich link fields are properly filled
      Enum.each(expected_data, fn {k, v} ->
        assert String.match?(response, ~r/meta property=\"og:#{k}\" content=\"#{v}/)
      end)
    end

    test "generate rich link for user",
         %{conn: conn} do
      # Insert user and extract data for the rich link

      user = insert(:user)

      community =
        insert(:community)
        |> Repo.preload(:subdomain)

      expected_data = %{
        description: md_to_txt(user.bio),
        title: user.name,
        url: community.subdomain.name,
        image: user.avatar,
        locale: user.location
      }

      # Submit GET request for a user rich link
      conn =
        %{conn | host: community.subdomain.name}
        |> get("/api/rich_link/profile/#{user.account}")

      response = html_response(conn, 200)

      # Check if all the rich link fields are properly filled
      Enum.each(expected_data, fn {k, v} ->
        assert String.match?(response, ~r/meta property=\"og:#{k}\" content=\"#{v}/)
      end)
    end

    test "generate rich link for product with image",
         %{conn: conn} do
      # Insert product and extract data for the rich link
      product =
        insert(:product)
        |> Repo.preload(:images)

      [image | _] = product.images

      community =
        insert(:community)
        |> Repo.preload(:subdomain)

      expected_data = %{
        description: md_to_txt(product.description),
        title: product.title,
        url: community.subdomain.name,
        image: image.uri,
        locale: nil
      }

      # Submit GET request for a product rich link
      conn =
        %{conn | host: community.subdomain.name}
        |> get("/api/rich_link/shop/#{product.id}")

      response = html_response(conn, 200)

      # Check if all the rich link fields are properly filled
      Enum.each(expected_data, fn {k, v} ->
        assert String.match?(response, ~r/meta property=\"og:#{k}\" content=\"#{v}/)
      end)
    end
  end

  test "generate rich link for product without image",
       %{conn: conn} do
    # Insert product without images and extract data for the rich link
    product = insert(:product, images: [])

    community =
      insert(:community)
      |> Repo.preload(:subdomain)

    expected_data = %{
      description: md_to_txt(product.description),
      title: product.title,
      url: community.subdomain.name,
      image: "https://buss.staging.cambiatus.io/images/logo-cambiatus-mobile.svg",
      locale: nil
    }

    # Submit GET request for a product rich link
    conn =
      %{conn | host: community.subdomain.name}
      |> get("/api/rich_link/shop/#{product.id}")

    response = html_response(conn, 200)

    # Check if all the rich link fields are properly filled
    Enum.each(expected_data, fn {k, v} ->
      assert String.match?(response, ~r/meta property=\"og:#{k}\" content=\"#{v}/)
    end)
  end

  defp md_to_txt(markdown) do
    # Convert markdown to plain text
    with {:ok, string, _} <- Earmark.as_html(markdown, escape: false) do
      string
      |> HtmlSanitizeEx.strip_tags()
      |> String.trim()
    else
      {:error, _} ->
        ""
    end
  end
end
