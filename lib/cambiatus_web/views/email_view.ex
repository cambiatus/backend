defmodule CambiatusWeb.EmailView do
  use CambiatusWeb, :view

  alias Earmark

  @doc "Renders the transfer email memo from markdown to html"
  def render("transfer.html", %{transfer: transfer}) do
    {:ok, html, []} =
      transfer.memo
      |> Earmark.as_html()

    html
  end
end
