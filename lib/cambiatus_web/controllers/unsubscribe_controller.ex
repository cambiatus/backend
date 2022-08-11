defmodule CambiatusWeb.UnsubscribeController do
  @moduledoc false

  use CambiatusWeb, :controller

  alias CambiatusWeb.AuthToken
  alias Cambiatus.Accounts

  def unsubscribe_page(conn, %{"token" => token} = _params) do
    case get_current_user(token) do
      {:ok, current_user} ->
        data = %{
          language: current_user.language || :"en-US",
          token: token,
          account: current_user.account,
          transfer_notification: current_user.transfer_notification,
          claim_notification: current_user.claim_notification,
          digest: current_user.digest
        }

        render(conn, "email_unsubscribe.html", %{data: data})

      {:error, _} ->
        conn |> resp(401, "Unauthorized") |> send_resp()
    end
  end

  def one_click(conn, %{"token" => token} = _params) do
    case(get_current_user(token)) do
      {:ok, current_user} ->
        Accounts.update_user(current_user, %{
          "transfer_notification" => false,
          "claim_notification" => false,
          "digest" => false
        })

        conn |> text("OK")

      {:error, _} ->
        conn |> resp(401, "Unauthorized") |> send_resp()
    end
  end

  def get_current_user(token) do
    with {:ok, %{id: account}} <- AuthToken.verify(token, "email"),
         %Accounts.User{} = current_user <- Accounts.get_user(account) do
      {:ok, current_user}
    else
      _ ->
        {:error, "Unauthorized"}
    end
  end
end
