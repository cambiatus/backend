defmodule CambiatusWeb.EmailViewTest do
  use CambiatusWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders transfer.html" do
    expected_html =
      "<h1>\nBig title</h1>\n<h2>\nSmall title</h2>\n<h3>\nSmaller title</h3>\n<ul>\n  <li>\nThis is a topic    <ul>\n      <li>\nThis is a subtopic      </li>\n    </ul>\n  </li>\n  <li>\nAnd another one  </li>\n</ul>\n<ul>\n  <li>\nDifferent topic  </li>\n</ul>\n"

    markdown = """
    # Big title
    ## Small title
    ### Smaller title
    - This is a topic
      - This is a subtopic
    - And another one
    + Different topic
    """

    assert render(CambiatusWeb.EmailView, "transfer.html", %{transfer: %{memo: markdown}}) ==
             expected_html
  end
end
