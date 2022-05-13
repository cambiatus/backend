defmodule CambiatusWeb.RichLinkView do
  use CambiatusWeb, :view

  require Earmark
  require HtmlSanitizeEx

  def md_to_txt(markdown) do
    with {:ok, string, _} <- Earmark.as_html(markdown) do
      HtmlSanitizeEx.strip_tags(string)
      |> String.trim()
    else
      {:error, _} ->
        ""
    end
  end
end
