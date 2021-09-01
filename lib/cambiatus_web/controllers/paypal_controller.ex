defmodule CambiatusWeb.PaypalController do
  @moduledoc """
  Controller that handles paypal callbacks
  """

  use CambiatusWeb, :controller

  alias Cambiatus.Payments

  def index(conn, params) do
    case Payments.create_payment_callback(%{payload: params}) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, error} ->
        Sentry.capture_message("Something went wrong while saving Paypal payload",
          extra: %{params: params, error: error}
        )

        text(conn, "Error")
    end
  end
end
