defmodule CambiatusWeb.Plugs.GetOrigin do
  @moduledoc """
  Plug used to provide GraphQL information about the origin, to determine community
  """

  @behaviour Plug

  import Plug.Conn

  alias Cambiatus.Commune

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> get_req_header("community-domain")
    |> get_domain()
    |> case do
      "" ->
        conn

      domain ->
        conn = Absinthe.Plug.assign_context(conn, domain: domain)

        case Commune.get_community_by_subdomain(domain) do
          {:ok, community} ->
            Absinthe.Plug.assign_context(conn, current_community_id: community.symbol)

          _ ->
            conn
        end
    end
  end

  def get_domain(["http://" <> domain]), do: domain
  def get_domain(["https://" <> domain]), do: domain
  def get_domain(_), do: ""
end
