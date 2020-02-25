defmodule Cambiatus.Notifications.HttpAdapter do
  @moduledoc """
  The HTTP client for sending web pushes in production.
  """

  @behaviour Cambiatus.Notifications.Adapter

  @impl true
  def send_web_push(body, sub) do
    WebPushEncryption.send_web_push(body, sub)
  end
end
