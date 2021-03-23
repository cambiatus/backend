defmodule CambiatusWeb.Plug.Subdomain do
  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _router) do
    get_subdomain(conn.host)
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
