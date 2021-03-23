defmodule CambiatusWeb.SubdomainRouter do
  use CambiatusWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", CambiatusWeb do
    pipe_through(:api)

    get("/", Subdomainer.Subdomain.PageController, :index)
  end
end
