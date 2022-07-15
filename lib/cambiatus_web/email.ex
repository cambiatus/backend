defmodule CambiatusWeb.Email do
  @moduledoc "Module responsible for mails templates"

  import Swoosh.Email
  import CambiatusWeb.Gettext

  use Phoenix.Swoosh, view: CambiatusWeb.EmailView

  alias Cambiatus.{Accounts, Mailer, Repo}
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

  def transfer(transfer) do
    transfer = Repo.preload(transfer, [:from, :to, [community: :subdomain]])
    community = transfer.community
    recipient = transfer.to

    new()
    |> from({"#{community.name} - Cambiatus", "no-reply@cambiatus.com"})
    |> to(recipient.email)
    |> subject(gettext("You received a new transfer on") <> " #{community.name}")
    |> render_body("transfer.html", render_params(transfer))
    |> header("List-Unsubscribe", one_click_unsub(recipient, community, "transfer_notification"))
    |> header("List-Unsubscribe-Post", "One-Click")
    |> set_language(transfer)
    |> Mailer.deliver()
  end

  def claim(claim) do
    community = claim.action.objective.community
    claimer = claim.claimer

    new()
    |> from({"#{community.name} - Cambiatus", "no-reply@cambiatus.com"})
    |> to(claimer.email)
    |> subject(gettext("Your claim was approved!"))
    |> header("List-Unsubscribe", one_click_unsub(claimer, community, "claim_notification"))
    |> header("List-Unsubscribe-Post", "One-Click")
    |> render_body("claim.html", render_params(claim))
    |> set_language(claim)
    |> Mailer.deliver()
  end

  # input is a community with preloaded news with less than 30 days and members with active digest
  def monthly_digest(community) do
    Enum.each(community.members, fn member ->
      new()
      |> from({"#{community.name} - Cambiatus", "no-reply@cambiatus.com"})
      |> to(member.email)
      |> set_language(member.language)
      |> subject(gettext("Community News"))
      |> header("List-Unsubscribe", one_click_unsub(member, community, "digest"))
      |> header("List-Unsubscribe-Post", "One-Click")
      |> render_body("monthly_digest.html", render_params(member, community))
      |> Mailer.deliver()
    end)
  end

  defp render_params(%Transfer{} = transfer) do
    unsub_link = unsub_link(transfer.to, transfer.community, transfer.to.language)
    %{transfer: transfer, unsub_link: unsub_link}
  end

  defp render_params(%Claim{} = claim) do
    unsub_link =
      unsub_link(claim.claimer, claim.action.objective.community, claim.claimer.language)

    %{claim: claim, unsub_link: unsub_link}
  end

  defp render_params(%User{} = user, %Community{} = community) do
    unsub_link = unsub_link(user, community, user.language)
    %{community: community, user: user, unsub_link: unsub_link}
  end

  def one_click_unsub(member, community, subject) do
    token = AuthToken.sign(member, "email")

    "<https://#{community.subdomain.name}/api/unsubscribe/#{subject}/#{token}>"
  end

  def unsub_link(member, community, language) do
    token = AuthToken.sign(member, "email")

    "https://#{community.subdomain.name}/unsubscribe?lang=#{language}&token=#{token}"
  end

  def current_year, do: DateTime.utc_now() |> Date.year_of_era() |> Tuple.to_list() |> hd

  def format_date(date) do
    [date.day, date.month, date.year]
    |> Enum.map_join("/", &to_string/1)
  end

  def set_language(mail, %Cambiatus.Commune.Transfer{:to_id => id} = _transfer) do
    user = Accounts.get_user!(id)

    set_language(mail, user.language)
  end

  def set_language(mail, %Cambiatus.Objectives.Claim{:claimer_id => id} = _claim) do
    user = Accounts.get_user!(id)

    set_language(mail, user.language)
  end

  def set_language(mail, language) when is_atom(language),
    do: set_language(mail, Atom.to_string(language))

  def set_language(mail, language) do
    if language, do: Gettext.put_locale(CambiatusWeb.Gettext, language)
    mail
  end
end
