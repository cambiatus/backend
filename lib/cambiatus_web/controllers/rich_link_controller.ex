defmodule CambiatusWeb.RichLinkController do
  @moduledoc """
  Get data and render html to be used for rich links (also known as Open Graphs).
  These rich links show additional information about the website when shared on social media
  and must be compliant with the [Open Grap Protocol](https://ogp.me/)
  """

  use CambiatusWeb, :controller

  alias CambiatusWeb.Resolvers.{Accounts, Commune, Shop}
  alias Cambiatus.Repo

  action_fallback(CambiatusWeb.FallbackController)

  @fallback_image "https://cambiatus-uploads.s3.amazonaws.com/cambiatus-uploads/b214c106482a46ad89f3272761d3f5b5"

  def rich_link(conn, params) do
    language = get_req_header(conn, "accept-language")

    data =
      with community_subdomain <- conn.host do
        case Map.get(params, "page") do
          ["shop", id] ->
            product_rich_link(id, community_subdomain, language)

          ["profile", account] ->
            user_rich_link(account, community_subdomain, language)

          ["shop", "categories", category_info] ->
            category_info
            |> String.split("-")
            |> List.last()
            |> category_rich_link(community_subdomain, language)

          _ ->
            community_rich_link(community_subdomain, language)
        end
      end

    case data do
      {:ok, data} ->
        render(conn, "rich_link.html", %{data: data})

      {:error, reason} ->
        render(conn, "error.json", %{error: reason})
    end
  end

  def product_rich_link(id, community_subdomain, language) do
    with {:ok, product} <- Shop.get_product(nil, %{id: id}, nil),
         {:ok, community} <- Commune.find_community(%{}, %{subdomain: community_subdomain}, %{}) do
      %{images: images, creator: creator} = Repo.preload(product, [:creator, :images])

      {:ok,
       %{
         description: product.description,
         title: product.title,
         url: community_subdomain <> "/shop/#{product.id}",
         image: if(images != [], do: Map.get(List.first(images), :uri), else: @fallback_image),
         locale: get_language(language, creator),
         price: product.price,
         currency: String.slice(community.symbol, 2, 7),
         creator: Map.get(creator, :name) || creator.account
       }}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def user_rich_link(account, community_subdomain, language) do
    case Accounts.get_user(nil, %{account: account}, nil) do
      {:ok, user} ->
        {:ok,
         %{
           description: user.bio,
           title: if(user.name, do: user.name, else: user.account),
           url: community_subdomain <> "/profile/#{user.account}",
           image: user.avatar,
           locale: get_language(language, user)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def category_rich_link(category_id, community_subdomain, language) do
    with category <- Cambiatus.Shop.get_category(category_id),
         {:ok, _community} <- Commune.find_community(%{}, %{subdomain: community_subdomain}, %{}) do
      {:ok,
       %{
         description: category.meta_description || category.description,
         title: category.meta_title || category.name,
         url: community_subdomain <> "/shop/categories/#{category.slug}-#{category.id}",
         image: category.icon_uri || category.image_uri || @fallback_image,
         locale: get_language(language, %{})
       }}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def community_rich_link(community_subdomain, language) do
    case Commune.find_community(%{}, %{subdomain: community_subdomain}, %{}) do
      {:ok, community} ->
        {:ok,
         %{
           description: community.description,
           title: community.name,
           url: community_subdomain,
           image: community.logo,
           locale: get_language(language, %{})
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_language(conn_header, map) do
    case conn_header do
      [language] ->
        String.to_existing_atom(language)

      _ ->
        Map.get(map, :language) || :"en-US"
    end
  end
end
