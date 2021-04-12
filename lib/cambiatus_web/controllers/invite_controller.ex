defmodule CambiatusWeb.InviteController do
  @moduledoc false

  use CambiatusWeb, :controller
  alias Cambiatus.Auth

  action_fallback(CambiatusWeb.FallbackController)

  def invite(conn, params) do
    case Auth.create_invitation(params) do
      {:ok, result} ->
        render(conn, "invite.json", %{result: result})

      {:error, "User don't belong to the community" = reason} ->
        conn
        |> put_status(422)
        |> render("error.json", %{error: reason})

      {:error, reason} ->
        render(conn, "error.json", %{error: reason})
    end
  end
end
