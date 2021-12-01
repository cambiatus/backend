defmodule CambiatusWeb.Email do
  @moduledoc "Module responsible for mails templates"

  import Swoosh.Email

  use Phoenix.Swoosh, view: CambiatusWeb.EmailView

  alias Cambiatus.{Mailer, Repo}

  def welcome(recipient) do
    new(
      to: recipient,
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
      subject: "You received a new transfer on #{transfer.community.name}",
      html_body: CambiatusWeb.EmailView.render("transfer.html", %{transfer: transfer})
    )
    |> Mailer.deliver()
  end

  def claim(claim) do
    new()
    |> from({"#{claim.action.objective.community.name} - Cambiatus", "no-reply@cambiatus.com"})
    |> to(claim.claimer.email)
    |> subject("Your claim was approved!")
    |> render_body("claim.html", %{claim: claim})
    |> Mailer.deliver()
  end

  # input is a community with preloaded news with less than 30 days and members with active digest
  def monthly_digest(community) do
    Enum.each(community.members, fn member ->
      new()
      |> from({"#{community.name} - Cambiatus", "no-reply@cambiatus.com"})
      |> to(member.email)
      |> subject("Community News")
      |> render_body("monthly_digest.html", %{community: community})
      |> Mailer.deliver()
    end)
  end

  def current_year, do: DateTime.utc_now() |> Date.year_of_era() |> Tuple.to_list() |> hd

  def format_date(date) do
    [date.day, date.month, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.join("/")
  end
end
