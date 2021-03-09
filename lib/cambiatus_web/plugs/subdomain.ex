defmodule CambiatusWeb.Plug.Subdomain do
  import Plug.Conn

  @doc false
  def init(default), do: default

  @doc false
  def call(conn, router) do
    get_subdomain(conn.host)
    |> IO.inspect(label: "SUBDOMAIN")
    |> case do
      subdomain when byte_size(subdomain) > 0 ->
        conn
        |> put_private(:subdomain, subdomain)
        |> router.call(router.init({}))
        |> halt()
      _ -> conn
    end
  end

  defp get_subdomain(host) do
    IO.inspect(host, label: "HOST")
    root_host = CambiatusWeb.Endpoint.config(:url)[:host]
    IO.inspect(root_host, label: "ROOT")
    String.replace(host, ~r/.?#{root_host}/, "")
  end
end
