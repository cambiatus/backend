defmodule CambiatusWeb.RichLinkController do
  use CambiatusWeb, :controller

  alias CambiatusWeb.Resolvers.{Accounts, Commune, Shop}
  alias Cambiatus.Repo
  require Earmark
  require HtmlSanitizeEx

  @rich_link_file Path.expand("../templates/rich_link.html.eex", __DIR__)

  def rich_link(conn, params) do
    data =
      case Map.get(params, "page") do
        ["shop"] ->
          product_rich_link(Map.get(params, "id"))

        ["profile", account] ->
          user_rich_link(account)

        [] ->
          community_rich_link(conn.host)

        _ ->
          send_resp(conn, 404, "Category not found")
      end

    case data do
      {:ok, data} ->
        response =
          %{data | description: md_to_txt(data.description)}
          |> Enum.into([])

        html(conn, EEx.eval_file(@rich_link_file, response))

      {:error, reason} ->
        send_resp(conn, 404, reason)
    end
  end

  def product_rich_link(id) do
    case Shop.get_product(nil, %{id: id}, nil) do
      {:ok, product} ->
        product = Repo.preload(product, :images)
        [image | _] = product.images

        {:ok,
         %{
           name: product.title,
           description: product.description,
           title: product.title,
           url: nil,
           image: image.uri,
           locale: nil
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def user_rich_link(account) do
    case Accounts.get_user(nil, %{account: account}, nil) do
      {:ok, user} ->
        {:ok,
         %{
           name: user.name,
           description: user.bio,
           title: user.name,
           url: user.email,
           image: user.avatar,
           locale: user.location
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def community_rich_link(community_subdomain) do
    case Commune.find_community(%{}, %{subdomain: community_subdomain}, %{}) do
      {:ok, community} ->
        {:ok,
         %{
           name: community.name,
           description: community.description,
           title: community.name,
           url: community_subdomain,
           image: community.logo,
           locale: nil
         }}

      {:error, reason} ->
        {:error, reason}
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
