defmodule CambiatusWeb.RichLinkView do
  use CambiatusWeb, :view

  import CambiatusWeb.Gettext

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

  def create_description(%{type: :product} = data) do
    Gettext.put_locale(CambiatusWeb.Gettext, Atom.to_string(data.locale))
    gettext("Sold by") <> " #{data.creator} - #{md_to_txt(data.description)}"
  end

  def create_description(%{type: :user} = data) do
    if data.description do
      md_to_txt(data.description)
    else
      Gettext.put_locale(CambiatusWeb.Gettext, Atom.to_string(data.locale))
      "#{data.title} " <> gettext("makes part of Cambiatus")
    end
  end

  def create_description(data), do: md_to_txt(data.description)

  def create_title(%{title: title, price: price, currency: currency}) do
    "#{price} #{currency} - #{title}"
  end

  def create_title(data), do: data.title
end
