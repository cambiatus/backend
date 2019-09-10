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
      subject: "Invitation for #{community} on BeSpiral",
      html_body:
        "#{inviter} invited you to join #{community} <br> <a href=\"http://dev.bespiral.io/#/register/#{
          invitation_id
        }\" target=\"_blank\">Click here to join</a>",
      text_body:
        "Use this URL to join #{community} on BeSpiral: http://dev.bespiral.io/#/register/#{
          invitation_id
        }"
    )
    |> Mailer.deliver_later()
  end
end
