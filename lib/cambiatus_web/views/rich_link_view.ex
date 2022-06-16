defmodule CambiatusWeb.RichLinkView do
  use CambiatusWeb, :view

  require Earmark
  require HtmlSanitizeEx

  def md_to_txt(markdown) do
    case Earmark.as_html(markdown, escape: false) do
      {:ok, string, _} ->
        string
        |> HtmlSanitizeEx.strip_tags()
        |> String.trim()

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
    "#{price} #{currency} - #{md_to_txt(description)} - Vendido por #{creator}"
  end

  def create_description(data), do: md_to_txt(data.description)
end
