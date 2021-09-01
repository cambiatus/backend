defmodule CambiatusWeb.PaypalController do
  @moduledoc """
  Controller that handles paypal callbacks
  """

  use CambiatusWeb, :controller

  alias Cambiatus.Payments

  def index(conn, params) do
    if Payments.create_payment_callback(%{payload: params}) do
      conn |> text("OK")
    else
      Sentry.capture_message("Something went wrong while saving Paypal payload", extra: params)
    end
  end
end
