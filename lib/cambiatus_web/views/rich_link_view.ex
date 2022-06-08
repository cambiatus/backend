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
end
