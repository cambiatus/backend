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

  def create_description(%{description: description, creator: creator, locale: locale}) do
    Gettext.put_locale(CambiatusWeb.Gettext, Atom.to_string(locale))
    gettext("Sold by") <> " #{creator} - #{md_to_txt(description)}"
  end

  def create_description(data), do: md_to_txt(data.description)

  def create_title(%{title: title, price: price, currency: currency}) do
    "#{price} #{currency} - #{title}"
  end

  def create_title(data), do: data.title

  def render("error.json", %{error: value}) when is_binary(value) do
    %{
      data: %{
        status: "failed",
        message: value
      }
    }
  end
end
