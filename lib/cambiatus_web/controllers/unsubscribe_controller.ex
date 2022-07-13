defmodule CambiatusWeb.UnsubscribeController do
  @moduledoc false

  use CambiatusWeb, :controller

  alias CambiatusWeb.AuthToken

  def one_click(conn, %{"token" => token, "subject" => subject} = _params) do
    with {:ok, %{id: account}} <- AuthToken.verify(token, "email"),
         %Cambiatus.Accounts.User{} = current_user <- Cambiatus.Accounts.get_user(account) do
      Cambiatus.Accounts.update_user(current_user, %{subject => false})

      conn |> text("OK")
    end
  end
end
