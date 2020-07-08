defmodule CambiatusWeb.Router do
  @moduledoc false

  use CambiatusWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])
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

    post("/auth/sign_in", AuthController, :sign_in)
    post("/auth/sign_up", AuthController, :sign_up)

    post("/ipfs", IPFSController, :save)
    post("/s3", S3Controller, :save)

    get("/chain/info", ChainController, :info)
    post("/chain/account", ChainController, :create_account)

    post("/invite", InviteController, :invite)
  end
end
