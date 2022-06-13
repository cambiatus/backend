defmodule CambiatusWeb.RichLinkView do
  use CambiatusWeb, :view

  require Earmark
  require HtmlSanitizeEx

  def md_to_txt(markdown) do
    with {:ok, string, _} <- Earmark.as_html(markdown, escape: false) do
      string
      |> HtmlSanitizeEx.strip_tags()
      |> String.trim()
    else
      {:error, _} ->
        ""
    end
  end

  def create_description(%{
        description: description,
        price: price,
        currency: currency,
        creator: creator
      }) do
    "<strong>#{price} #{currency}</strong> - #{md_to_txt(description)} - Vendido por #{creator}"
  end

  def create_description(data), do: md_to_txt(data.description)
end
