defmodule Cambiatus.Mails.UserMail do
  @moduledoc "Module responsible for mails templates"

  import Bamboo.Email

  alias Cambiatus.Mailer

  def welcome_email(recipient) do
    new_email(
      to: recipient,
      from: Mailer.sender(),
      subject: "Welcome to the app.",
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    )
    |> Mailer.deliver_later()
  end

  def endpoint() do
    CambiatusWeb.Endpoint.url()
    |> case do
      "http://localhost:4000" ->
        "http://localhost:"

      "https://api.cambiatus.io:8025" ->
        "https://api.cambiatus.io"

      domain ->
        api_url = Regex.replace(~r{(-api)}, domain, "")
        Regex.replace(~r{(:8025)}, api_url, "")
    end
  end
end
