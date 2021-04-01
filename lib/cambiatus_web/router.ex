defmodule CambiatusWeb.Router do
  @moduledoc false

  use CambiatusWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])
    plug(CambiatusWeb.Plugs.SetCurrentUser)
    # plug(CambiatusWeb.Plugs.SetPhrase)
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  if Application.get_env(:cambiatus, :env) == :dev do
    scope "/dev" do
      pipe_through([:browser])

      forward("/mailbox", Bamboo.SentEmailViewerPlug)
    end
  end

  scope "/api" do
    pipe_through(:api)

    forward(
      "/graph",
      Absinthe.Plug,
      schema: CambiatusWeb.Schema,
      socket: CambiatusWeb.UserSocket
    )

    forward(
      "/graphiql",
      Absinthe.Plug.GraphiQL,
      schema: CambiatusWeb.Schema,
      socket: CambiatusWeb.UserSocket,
      interface: :playground
    )
  end

  scope "/api", CambiatusWeb do
    pipe_through(:api)

    get("/health_check", HealthCheckController, :index)

    post("/ipfs", IPFSController, :save)
    post("/upload", UploadController, :save)

    get("/chain/info", ChainController, :info)

    post("/invite", InviteController, :invite)
  end
end
