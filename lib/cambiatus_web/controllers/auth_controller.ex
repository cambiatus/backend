defmodule CambiatusWeb.AuthController do
  use CambiatusWeb, :controller

  alias Cambiatus.Accounts.User
  alias Cambiatus.Auth

  action_fallback(CambiatusWeb.FallbackController)

  @spec sign_in(Plug.Conn.t(), map) :: {:error, :not_found} | {:ok, map} | Plug.Conn.t()
  def sign_in(conn, %{"user" => user_params, "invitation_id" => invitation_id}) do
    with {:ok, %User{} = user} <- Auth.sign_in(user_params, invitation_id) do
      render(conn, "auth.json", user: user)
    end
  end

  def sign_in(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Auth.sign_in(user_params) do
      render(conn, "auth.json", user: user)
    end
  end

  @spec sign_up(Plug.Conn.t(), map) :: Plug.Conn.t()
  def sign_up(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/api/graph")
  end
end
