defmodule CambiatusWeb.EmailViewTest do
  use CambiatusWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders transfer.html" do
    expected_html =
      "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"UTF-8\">\n<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<title>Email recieved</title>\n</head>\n<body>\n  <h1>\nBig title</h1>\n<h2>\nSmall title</h2>\n<h3>\nSmaller title</h3>\n<ul>\n  <li>\nThis is a topic    <ul>\n      <li>\nThis is a subtopic      </li>\n    </ul>\n  </li>\n  <li>\nAnd another one  </li>\n</ul>\n<ul>\n  <li>\nDifferent topic  </li>\n</ul>\n\n</body>\n</html>\n"

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
