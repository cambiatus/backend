defmodule CambiatusWeb.Plug.Subdomain do
  @moduledoc """
  This plug adds the subdomain
  """
  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _router) do
    conn.host
    |> get_subdomain()
    |> case do
      subdomain when byte_size(subdomain) > 0 ->
        conn
        |> put_private(:subdomain, subdomain)
        # |> router.call(router.init({}))
        # |> halt()
      _ -> conn
    end
  end

  defp get_subdomain(host) do
    root_host = CambiatusWeb.Endpoint.config(:url)[:host]
    String.replace(host, ~r/.?#{root_host}/, "")
  end
end
