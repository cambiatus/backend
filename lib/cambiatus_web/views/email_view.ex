defmodule CambiatusWeb.EmailView do
  use CambiatusWeb, :view

  alias Earmark

  @doc "Renders the transfer email memo from markdown to html"
  def render("transfer.html", %{transfer: transfer}) do
    {:ok, html, []} = Earmark.as_html(transfer.memo)

    html
  end
end
