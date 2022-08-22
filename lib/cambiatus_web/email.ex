defmodule CambiatusWeb.Email do
  @moduledoc "Module responsible for mails templates"

  import Swoosh.Email
  import CambiatusWeb.Gettext

  use Phoenix.Swoosh, view: CambiatusWeb.EmailView

  alias Cambiatus.{Mailer, Repo}
  alias CambiatusWeb.AuthToken
  alias Cambiatus.Commune.{Community, Transfer}
  alias Cambiatus.Accounts.User
  alias Cambiatus.Objectives.Claim

  def welcome(user) do
    new(
      to: user.email,
      from: Mailer.sender(),
      subject: "Welcome to the app.",
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    )
    |> Mailer.deliver()
  end

  def transfer(%Transfer{} = transfer) do
    transfer = Repo.preload(transfer, [:from, :to, [community: :subdomain]])

    compose_email_headers(transfer.to, transfer.community)
    |> subject(gettext("You received a new transfer on") <> " #{transfer.community.name}")
    |> render_body("transfer.html", render_params(transfer))
    |> Mailer.deliver()
  end

  def claim(%Claim{} = claim) do
    claim = Repo.preload(claim, [:claimer, action: [objective: [community: :subdomain]]])

    compose_email_headers(claim.claimer, claim.action.objective.community)
    |> subject(gettext("Your claim was approved!"))
    |> render_body("claim.html", render_params(claim))
    |> Mailer.deliver()
  end

  # input is a community with preloaded news with less than 30 days and members with active digest
  def monthly_digest(community) do
    Enum.each(community.members, fn member ->
      compose_email_headers(member, community)
      |> subject("#{community.name} - " <> gettext("Community News"))
      |> render_body("monthly_digest.html", render_params(member, community))
      |> Mailer.deliver()
    end)
  end

  def compose_email_headers(recipient, community) do
    new()
    |> from({"#{community.name} - Cambiatus", Mailer.sender()})
    |> to(recipient.email)
    |> set_language(recipient.language)
    |> header("List-Unsubscribe", "<#{one_click_unsub(recipient, community)}>")
    |> header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
  end

  defp render_params(%Transfer{} = transfer) do
    unsub_link = unsub_link(transfer.to, transfer.community)
    %{transfer: transfer, unsub_link: unsub_link}
  end

  defp render_params(%Claim{} = claim) do
    unsub_link = unsub_link(claim.claimer, claim.action.objective.community)

    %{claim: claim, unsub_link: unsub_link}
  end

  defp render_params(%User{} = user, %Community{} = community) do
    unsub_link = unsub_link(user, community)
    %{community: community, user: user, unsub_link: unsub_link}
  end

  def one_click_unsub(member, community) do
    token = AuthToken.sign(member, "email")

    "https://#{community.subdomain.name}/api/unsubscribe?token=#{token}"
  end

  def unsub_link(member, community) do
    token = AuthToken.sign(member, "email")

    "https://#{community.subdomain.name}/mailer/unsubscribe?token=#{token}"
  end

  def set_language(mail, language) do
    language = if language, do: Atom.to_string(language), else: "en-US"
    Gettext.put_locale(CambiatusWeb.Gettext, language)
    CambiatusWeb.Cldr.put_gettext_locale(language)

    mail
  end
end
