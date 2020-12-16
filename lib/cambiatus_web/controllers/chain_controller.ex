defmodule CambiatusWeb.ChainController do
  use CambiatusWeb, :controller

  alias Cambiatus.Eos
  alias EOSRPC.Chain

  action_fallback(CambiatusWeb.FallbackController)

  @spec info(Plug.Conn.t(), any) :: Plug.Conn.t()
  def info(conn, _params) do
    {:ok, response} = Chain.get_info()
    json(conn, response.body)
  end

end
