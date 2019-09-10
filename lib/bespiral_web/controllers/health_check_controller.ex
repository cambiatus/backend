defmodule BeSpiralWeb.HealthCheckController do
  use BeSpiralWeb, :controller

  def index(conn, _params), do: conn |> text("OK")
end
