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
end
