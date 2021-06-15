defmodule CambiatusWeb.Email do
  @moduledoc "Module responsible for mails templates"

  import Swoosh.Email

  use Phoenix.Swoosh, view: CambiatusWeb.EmailView, layout: {CambiatusWeb.LayoutView, :email}

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

    new()
    |> from({"#{transfer.community.name} - Cambiatus", "no-reply@cambiatus.com"})
    |> to(transfer.to.email)
    |> subject("You received a new transfer on #{transfer.community.name}")
    |> render_body("transfer.html", %{transfer: transfer})
    |> Mailer.deliver()
  end

  def current_year(), do: DateTime.utc_now() |> Date.year_of_era() |> Tuple.to_list() |> hd

  def format_date(date) do
    [date.day, date.month, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.join("/")
  end
end
