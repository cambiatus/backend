defmodule CambiatusWeb.UnsubscribeController do
  @moduledoc false

  use CambiatusWeb, :controller

  alias CambiatusWeb.AuthToken
  alias Cambiatus.Accounts

  def one_click(conn, %{"token" => token, "list" => list} = _params) do
    with {:ok, %{id: account}} <- AuthToken.verify(token, "email"),
         %Accounts.User{} = current_user <- Accounts.get_user(account) do
      Accounts.update_user(current_user, %{list => false})

      conn |> text("OK")
    end
  end
end
