defmodule BeSpiralWeb.InviteController do
  @moduledoc false

  use BeSpiralWeb, :controller
  alias BeSpiral.Auth

  action_fallback(BeSpiralWeb.FallbackController)

  def invite(conn, params) do
    with result <- Auth.create_invite(params) do
      render(conn, %{result: result})
    end
  end
end
