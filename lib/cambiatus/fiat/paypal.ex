defmodule Cambiatus.Fiat.Paypal do
  @moduledoc """
  PayPal API wrapper
  """

  use Tesla

  plug(Tesla.Middleware.JSON)

  @doc """
  params = %{
    sender_batch_header: %{
      sender_batch_id: "some reference id",
      email_subject: "senders email"
    },
    items: [
      %{
        recipient_type: "EMAIL",
        receiver: "receivers email",
        note: "some note to attach on the payment",
        sender_item_id: "transfer id",
        amount: %{
          currency: "USD",
          value: "1.00"
        }
      }
    ]
  }
  """
  def payout(params) do
    "/v1/payments/payout"
    |> url()
    |> post(params)
  end

  def url(path) do
    :url
    |> get_config()
    |> Kernel.<>(path)
  end

  def get_config(key) do
    Application.get_env(:cambiatus, __MODULE__, key)
  end
end
