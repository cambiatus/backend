defmodule CambiatusWeb.EmailView do
  use CambiatusWeb, :view

  alias Earmark

  # https://github.com/pragdave/earmark#earmarkas_html
  # https://github.com/cambiatus/backend/issues/184

  def render("transfer.html", %{transfer: transfer}) do
    {:ok, html, []} =
      transfer.memo
      # Renders the markdown and removes all '\n'
      |> Earmark.as_html()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email recieved</title>
    </head>
    <body>
      #{html}
    </body>
    </html>
    """
  end

  # %Cambiatus.Commune.Transfer{
  #   __meta__: #Ecto.Schema.Metadata<:built, "transfers">,
  #   amount: "47",
  #   community: #Ecto.Association.NotLoaded<association :community is not loaded>,
  #   community_id: nil,
  #   created_at: ~N[2021-10-05 11:11:39.988480],
  #   created_block: "811",
  #   created_eos_account: "created-eos-acc-811",
  #   created_tx: "created-tx-439",
  #   from: %Cambiatus.Accounts.User{
  #     __meta__: #Ecto.Schema.Metadata<:built, "users">,
  #     account: "wxevvflyuqnl",
  #     address: #Ecto.Association.NotLoaded<association :address is not loaded>,
  #     avatar: "ava-390",
  #     bio: "my bio  is so awesome I put a number in it 390",
  #     chat_token: nil,
  #     chat_user_id: nil,
  #     claims: #Ecto.Association.NotLoaded<association :claims is not loaded>,
  #     communities: #Ecto.Association.NotLoaded<association :communities is not loaded>,
  #     contacts: #Ecto.Association.NotLoaded<association :contacts is not loaded>,
  #     created_at: nil,
  #     created_block: "809",
  #     created_eos_account: "eos-acc-809",
  #     created_tx: "tx-437",
  #     email: "mail390@company390.com",
  #     from_transfers: #Ecto.Association.NotLoaded<association :from_transfers is not loaded>,
  #     interests: "playing-390, coding-390, testing-390",
  #     invitations: #Ecto.Association.NotLoaded<association :invitations is not loaded>,
  #     kyc: #Ecto.Association.NotLoaded<association :kyc is not loaded>,
  #     location: "some loc 390",
  #     name: "u-name676",
  #     network: #Ecto.Association.NotLoaded<association :network is not loaded>,
  #     orders: #Ecto.Association.NotLoaded<association :orders is not loaded>,
  #     products: #Ecto.Association.NotLoaded<association :products is not loaded>,
  #     push_subscriptions: #Ecto.Association.NotLoaded<association :push_subscriptions is not loaded>,
  #     to_transfers: #Ecto.Association.NotLoaded<association :to_transfers is not loaded>
  #   },
  #   from_id: nil,
  #   id: nil,
  #   memo: "the memo is - 47",
  #   to: %Cambiatus.Accounts.User{
  #     __meta__: #Ecto.Schema.Metadata<:built, "users">,
  #     account: "fvcwcxboyxzf",
  #     address: #Ecto.Association.NotLoaded<association :address is not loaded>,
  #     avatar: "ava-391",
  #     bio: "my bio  is so awesome I put a number in it 391",
  #     chat_token: nil,
  #     chat_user_id: nil,
  #     claims: #Ecto.Association.NotLoaded<association :claims is not loaded>,
  #     communities: #Ecto.Association.NotLoaded<association :communities is not loaded>,
  #     contacts: #Ecto.Association.NotLoaded<association :contacts is not loaded>,
  #     created_at: nil,
  #     created_block: "810",
  #     created_eos_account: "eos-acc-810",
  #     created_tx: "tx-438",
  #     email: "mail391@company391.com",
  #     from_transfers: #Ecto.Association.NotLoaded<association :from_transfers is not loaded>,
  #     interests: "playing-391, coding-391, testing-391",
  #     invitations: #Ecto.Association.NotLoaded<association :invitations is not loaded>,
  #     kyc: #Ecto.Association.NotLoaded<association :kyc is not loaded>,
  #     location: "some loc 391",
  #     name: "u-name677",
  #     network: #Ecto.Association.NotLoaded<association :network is not loaded>,
  #     orders: #Ecto.Association.NotLoaded<association :orders is not loaded>,
  #     products: #Ecto.Association.NotLoaded<association :products is not loaded>,
  #     push_subscriptions: #Ecto.Association.NotLoaded<association :push_subscriptions is not loaded>,
  #     to_transfers: #Ecto.Association.NotLoaded<association :to_transfers is not loaded>
  #   },
  #   to_id: nil
  # }
end
