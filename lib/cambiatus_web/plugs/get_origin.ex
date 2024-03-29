defmodule CambiatusWeb.Plugs.GetOrigin do
  @moduledoc """
  Plug used to provide GraphQL information about the origin, to determine community
  """

  @behaviour Plug

  import Plug.Conn

  alias Cambiatus.Commune

  def init(opts), do: opts

  def call(conn, _) do
    with [domain] <- get_req_header(conn, "community-domain"),
         {:ok, domain} <- get_domain_from_header(domain),
         {:ok, current_community} <- Commune.get_community_by_subdomain(domain) do
      conn
      |> assign(:current_community, current_community)
      |> Absinthe.Plug.assign_context(%{domain: domain, current_community: current_community})
    else
      {:error, error} ->
        Sentry.capture_message("Could not get community from subdomain",
          extra: %{conn: conn, error: error}
        )

        {:error, error}

      _ ->
        with domain <- get_domain_from_host(conn.host),
             {:ok, current_community} <- Commune.get_community_by_subdomain(domain) do
          conn
          |> assign(:current_community, current_community)
          |> Absinthe.Plug.assign_context(%{domain: domain, current_community: current_community})
        else
          {:error, error} ->
            Sentry.capture_message("Could not assign community into context",
              extra: %{conn: conn, error: error}
            )

            conn
        end
    end
  end

  def get_domain_from_header("http://" <> domain), do: {:ok, domain}
  def get_domain_from_header("https://" <> domain), do: {:ok, domain}
  def get_domain_from_header(_), do: :error

  def get_domain_from_host(host), do: host |> String.split(":") |> List.first()
end
