defmodule BeSpiralWeb.InviteController do
  @moduledoc false

  use BeSpiralWeb, :controller
  alias BeSpiral.Auth

  def invite(conn, params) do
    with :ok <- Auth.create_invites(params) do
      render(conn, %{ok: ""})
    end
  end
end
