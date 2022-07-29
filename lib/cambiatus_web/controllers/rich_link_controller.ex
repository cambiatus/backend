defmodule CambiatusWeb.RichLinkController do
  @moduledoc """
  Get data and render html to be used for rich links (also known as Open Graphs).
  These rich links show additional information about the website when shared on social media
  and must be compliant with the [Open Grap Protocol](https://ogp.me/)
  """

  use CambiatusWeb, :controller

  alias CambiatusWeb.Resolvers.{Accounts, Shop}
  alias Cambiatus.Repo

  @fallback_image "https://cambiatus-uploads.s3.amazonaws.com/cambiatus-uploads/b214c106482a46ad89f3272761d3f5b5"

  def rich_link(conn, params) do
    language = get_req_header(conn, "accept-language")

    data =
      with {:ok, community} <- Map.fetch(conn.assigns, :current_community),
           community <- Repo.preload(community, :subdomain) do
        case Map.get(params, "page") do
          ["shop", id] ->
            product_rich_link(id, community, language)

          ["profile", account] ->
            user_rich_link(account, community, language)

          ["shop", "categories", category_info] ->
            category_info
            |> String.split("-")
            |> List.last()
            |> category_rich_link(community, language)

          _ ->
            community_rich_link(community, language)
        end
      end

    case data do
      {:ok, data} ->
        render(conn, "rich_link.html", %{data: data})

      {:error, reason} ->
        send_resp(conn, 404, reason)
    end
  end

  def product_rich_link(id, community, language) do
    case Shop.get_product(nil, %{id: id}, nil) do
      {:ok, product} ->
        %{images: images, creator: creator} = Repo.preload(product, [:creator, :images])

        {:ok,
         %{
           type: :product,
           description: product.description,
           title: product.title,
           url: community.subdomain.name <> "/shop/#{product.id}",
           image: if(images != [], do: Map.get(List.first(images), :uri), else: @fallback_image),
           locale: get_language(language, creator),
           price: product.price,
           currency: String.split(community.symbol, ",") |> Enum.at(1),
           creator: Map.get(creator, :name) || creator.account
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def user_rich_link(account, community, language) do
    case Accounts.get_user(nil, %{account: account}, nil) do
      {:ok, user} ->
        {:ok,
         %{
           type: :user,
           description: user.bio,
           title: user.name || user.account,
           url: community.subdomain.name <> "/profile/#{user.account}",
           image: user.avatar || @fallback_image,
           locale: get_language(language, user)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def category_rich_link(category_id, community, language) do
    case Cambiatus.Shop.get_category(category_id) do
      nil ->
        {:error, "Category not found"}

      category ->
        {:ok,
         %{
           type: :category,
           description: category.meta_description || category.description,
           title: category.meta_title || category.name,
           url: community.subdomain.name <> "/shop/categories/#{category.slug}-#{category.id}",
           image: category.icon_uri || category.image_uri || @fallback_image,
           locale: get_language(language, %{})
         }}
    end
  end

  def community_rich_link(community, language) do
    {:ok,
     %{
       type: :community,
       description: community.description,
       title: community.name,
       url: community.subdomain.name,
       image: community.logo,
       locale: get_language(language, %{})
     }}
  end

  defp get_language(conn_header, map) do
    case conn_header do
      [language] ->
        String.to_atom(language)

      _ ->
        Map.get(map, :language) || :"en-US"
    end
  end
end
