defmodule CambiatusWeb.Plugs.SetCSP do
  @moduledoc """
  Plug used to define the Content Security Policy used when the backend diplays HTML pages

  This makes our pages more resilitent to attacks such as XSS and CSRF
  """

  @behaviour Plug

  use Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _) do
    policies =
      Enum.reduce(list_policies(), "", fn {policy, srcs}, csp ->
        srcs = Enum.join(srcs, " ")

        csp <> "#{policy} #{srcs}; "
      end)

    put_secure_browser_headers(conn, %{"content-security-policy" => policies})
  end

  def list_policies do
    %{
      "default-src" => ["'self'"],
      "style-src" => ["'unsafe-inline'", "fonts.googleapis.com"],
      "font-src" => ["fonts.googleapis.com", "fonts.gstatic.com"],
      "img-src" => ["cambiatus-uploads.s3.amazonaws.com", "uploads-ssl.webflow.com"],
      "script-src" => ["'unsafe-inline'"]
    }
  end
end
