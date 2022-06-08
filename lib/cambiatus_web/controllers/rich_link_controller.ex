defmodule CambiatusWeb.RichLinkController do
  @moduledoc """
  Get data and render html to be used for rich links (also known as Open Graphs).
  These rich links show additional information about the website when shared on social media
  and must be compliant with the [Open Grap Protocol](https://ogp.me/)
  """

  use CambiatusWeb, :controller

  alias CambiatusWeb.Resolvers.{Accounts, Commune, Shop}
  alias Cambiatus.Repo

  def rich_link(conn, params) do
    data =
      with community_subdomain <- conn.host do
        case Map.get(params, "page") do
          ["shop", id] ->
            product_rich_link(id, community_subdomain)

          ["profile", account] ->
            user_rich_link(account, community_subdomain)

          _ ->
            community_rich_link(community_subdomain)
        end
      end

    case data do
      {:ok, data} ->
        render(conn, "rich_link.html", %{data: data})

      {:error, reason} ->
        send_resp(conn, 404, reason)
    end
  end

  def product_rich_link(id, community_subdomain) do
    get_image = fn product ->
      with product = Repo.preload(product, :images),
           [image | _] <- product.images do
        image.uri
      else
        _ ->
          "https://cambiatus-uploads.s3.amazonaws.com/cambiatus-uploads/b214c106482a46ad89f3272761d3f5b5"
      end
    end

    case Shop.get_product(nil, %{id: id}, nil) do
      {:ok, product} ->
        {:ok,
         %{
           description: product.description,
           title: product.title,
           url: community_subdomain <> "/shop/#{product.id}",
           image: get_image.(product),
           locale: nil
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def user_rich_link(account, community_subdomain) do
    case Accounts.get_user(nil, %{account: account}, nil) do
      {:ok, user} ->
        {:ok,
         %{
           description: user.bio,
           title: if(user.name, do: user.name, else: user.account),
           url: community_subdomain <> "/profile/#{user.account}",
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
end