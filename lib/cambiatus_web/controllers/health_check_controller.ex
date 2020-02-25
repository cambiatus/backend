defmodule CambiatusWeb.HealthCheckController do
  use CambiatusWeb, :controller

  def index(conn, _params), do: conn |> text("OK")
end
