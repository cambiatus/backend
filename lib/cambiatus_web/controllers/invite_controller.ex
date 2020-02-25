defmodule CambiatusWeb.InviteController do
  @moduledoc false

  use CambiatusWeb, :controller
  alias Cambiatus.Auth

  action_fallback(CambiatusWeb.FallbackController)

  def invite(conn, params) do
    with result <- Auth.create_invite(params) do
      render(conn, %{result: result})
    end
  end
end
