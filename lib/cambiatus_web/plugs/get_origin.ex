defmodule CambiatusWeb.Plugs.GetOrigin do
  @moduledoc """
  Plug used to provide GraphQL information about the origin, to determine community
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> get_req_header("community-domain")
    |> get_domain()
    |> case do
      "" ->
        conn

      domain ->
        Absinthe.Plug.assign_context(conn, domain: domain)
    end
  end

  def get_domain(["http://" <> domain]), do: domain
  def get_domain(["https://" <> domain]), do: domain
  def get_domain(_), do: ""
end
