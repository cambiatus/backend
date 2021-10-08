defmodule CambiatusWeb.EmailView do
  use CambiatusWeb, :view

  alias Earmark

  def render("transfer.html", %{transfer: transfer}) do
    {:ok, html, []} =
      transfer.memo
      # Renders the markdown and removes all '\n'
      |> Earmark.as_html()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email recieved</title>
    </head>
    <body>
      #{html}
    </body>
    </html>
    """
  end
end
