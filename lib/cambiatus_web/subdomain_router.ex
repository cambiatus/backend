defmodule CambiatusWeb.SubdomainRouter do
  use CambiatusWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", CambiatusWeb do
    pipe_through :api

    get "/", Subdomainer.Subdomain.PageController, :index
  end
end
