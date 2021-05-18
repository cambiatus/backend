defmodule Cambiatus.Mails.UserMail do
  @moduledoc "Module responsible for mails templates"

  import Bamboo.Email
  import Bamboo.SendGridHelper

  alias Cambiatus.Mailer
  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community

  def welcome(recipient) do
    new_email(
      to: recipient,
      from: Mailer.sender(),
      subject: "Welcome to the app.",
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    )
    |> Mailer.deliver_later()
  end

  def transfer(%{from: %User{} = from, to: %User{} = to, community: %Community{} = community} = t) do
    new_email(to: to.email, from: Mailer.sender(), subject: "Transfer Received")
    |> with_template("d-c7e484fa688740e8a293dda32ceb520d")
    |> add_dynamic_field("community_logo", community.logo)
    |> add_dynamic_field("community_symbol", community.symbol)
    |> add_dynamic_field("year", current_year())
    |> add_dynamic_field("user_name", to.name)
    |> add_dynamic_field("transfer_from", from.name)
    |> add_dynamic_field("transfer_from_avatar", from.avatar)
    |> add_dynamic_field("transfer_amount", t.amount)
    |> add_dynamic_field("transfer_date", t.created_at |> format_date())
    |> add_dynamic_field("transfer_memo", t.memo)
    |> Mailer.deliver_later()
  end

  def current_year(), do: DateTime.utc_now() |> Date.year_of_era() |> Tuple.to_list() |> hd

  def format_date(date) do
    [date.day, date.month, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.join("/")
  end
end
