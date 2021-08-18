defmodule CambiatusWeb.PaypalController do
  @moduledoc """
  Controller that handles paypal callbacks
  """

  use CambiatusWeb, :controller

  def index(conn, params) do
    IO.inspect(params)
    conn |> text("OK")
  end
end
