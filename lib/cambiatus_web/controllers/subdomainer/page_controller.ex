defmodule CambiatusWeb.Subdomainer.Subdomain.PageController do
  use CambiatusWeb, :controller

  def index(conn, _params) do
    json(conn, "Subdomain home page for #{conn.private[:subdomain]}")
  end
end
