defmodule BeSpiral.Mails.UserMail do
  @moduledoc "Module responsible for mails templates"

  import Bamboo.Email

  alias BeSpiral.Mailer

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

  def invitation(recipient, %{inviter: inviter, community_name: community, id: invitation_id}) do
    new_email(
      to: recipient,
      from: Mailer.sender(),
      subject: "Invitation for #{community} on Cambiatus",
      html_body:
        "#{inviter} invited you to join #{community} <br> <a href=\"#{endpoint()}/register/#{
          invitation_id
        }\" target=\"_blank\">Click here to join</a>",
      text_body:
        "Use this URL to join #{community} on Cambiatus: #{endpoint()}/register/#{
          invitation_id
        }"
    )
    |> Mailer.deliver_later()
  end

  def endpoint() do
    BeSpiralWeb.Endpoint.url()
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
