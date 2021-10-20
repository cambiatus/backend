defmodule CambiatusWeb.PaypalController do
  @moduledoc """
  Controller that handles paypal callbacks
  """

  use CambiatusWeb, :controller

  alias Cambiatus.Payments

  def index(conn, params) do
    with {:ok, payment_callback} <- Payments.create_payment_callback(%{payload: params}),
         {:ok, _} <- Payments.schedule_payment_callback_worker(payment_callback.id) do
      text(conn, "OK")
    else
      {:error, error} ->
        Sentry.capture_message("Something went wrong while saving Paypal payload",
          extra: %{params: params, error: error}
        )

        text(conn, "Error")
    end
  end
end
