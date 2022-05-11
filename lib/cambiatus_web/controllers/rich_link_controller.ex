defmodule CambiatusWeb.RichLinkController do
  use CambiatusWeb, :controller

  alias CambiatusWeb.Resolvers.{Accounts, Commune, Shop}
  require Pandex

  @rich_link_file Path.expand("../templates/rich_link.html.eex", __DIR__)

  def rich_link(conn, params) do
    data =
      case Map.get(params, "page") do
        ["shop"] ->
          Shop.get_product_rich_link(Map.get(params, "id"))

        ["profile", user] ->
          Accounts.get_user_rich_link(user)

        [] ->
          Commune.get_community_rich_link(conn.host)

        _ ->
          send_resp(conn, 404, "Category not found")
      end

    case data do
      {:ok, data} ->
        response =
          data
          |> Enum.map(fn {k, v} -> {k, md_to_txt(v)} end)
          |> Enum.into([])

        html(conn, EEx.eval_file(@rich_link_file, response))

      {:error, reason} ->
        send_resp(conn, 404, reason)
    end
  end

  defp md_to_txt(markdown) do
    with {:ok, string} <- Pandex.markdown_to_plain(markdown) do
      String.trim(string)
    else
      {:error, _} ->
        ""
    end
  end
end
