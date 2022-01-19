defmodule CambiatusWeb.Email do
  @moduledoc "Module responsible for mails templates"

  import Swoosh.Email
  import CambiatusWeb.Gettext

  use Phoenix.Swoosh, view: CambiatusWeb.EmailView

  alias Cambiatus.{Accounts, Mailer, Repo}

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

    new(
      to: transfer.to.email,
      from: {"#{transfer.community.name} - Cambiatus", "no-reply@cambiatus.com"},
      subject: gettext("You received a new transfer on") <> "#{transfer.community.name}",
      html_body: CambiatusWeb.EmailView.render("transfer.html", %{transfer: transfer})
    )
    |> set_language(transfer)
    |> Mailer.deliver()
  end

  def claim(claim) do
    new()
    |> from({"#{claim.action.objective.community.name} - Cambiatus", "no-reply@cambiatus.com"})
    |> to(claim.claimer.email)
    |> subject(gettext("Your claim was approved!"))
    |> render_body("claim.html", %{claim: claim})
    |> set_language(claim)
    |> Mailer.deliver()
  end

  def current_year(), do: DateTime.utc_now() |> Date.year_of_era() |> Tuple.to_list() |> hd

  def format_date(date) do
    [date.day, date.month, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.join("/")
  end

  def set_language(mail, %Cambiatus.Commune.Transfer{:to_id => id} = _transfer) do
    user = Accounts.get_user!(id)

    if user.language do
      Gettext.put_locale(Cambiatus.Gettext, user.language)
    end

    mail
  end

  def set_language(mail, %Cambiatus.Objectives.Claim{:claimer_id => id} = _claim) do
    user = Accounts.get_user!(id)

    if user.language do
      Gettext.put_locale(Cambiatus.Gettext, user.language)
    end

    mail
  end
end
