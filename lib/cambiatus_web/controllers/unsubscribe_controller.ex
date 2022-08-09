defmodule CambiatusWeb.UnsubscribeController do
  @moduledoc false

  use CambiatusWeb, :controller

  alias CambiatusWeb.AuthToken
  alias Cambiatus.Accounts

  def unsubscribe(conn, %{"token" => token} = _params) do
    with {:ok, %{id: account}} <- AuthToken.verify(token, "email"),
         %Accounts.User{} = current_user <- Accounts.get_user(account) do
      case conn.method do
        "GET" ->
          unsubscribe_page(conn, current_user, token)

        "POST" ->
          one_click(conn, current_user)
      end
    else
      _ ->
        conn |> resp(401, "Unathorized") |> send_resp()
    end
  end

  def unsubscribe_page(conn, current_user, token) do
    data = %{
      language: current_user.language || :"en-US",
      token: token
    }

    render(conn, "email_unsubscribe.html", %{data: data})
  end

  def one_click(conn, current_user) do
    Accounts.update_user(current_user, %{
      "transfer_notification" => false,
      "claim_notification" => false,
      "digest" => false
    })

    conn |> text("OK")
  end
end
