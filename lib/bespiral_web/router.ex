defmodule BeSpiralWeb.Router do
  @moduledoc false

  use BeSpiralWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  if Application.get_env(:bespiral, :env) == :dev do
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
      schema: BeSpiralWeb.Schema,
      socket: BeSpiralWeb.UserSocket
    )

    forward(
      "/graphiql",
      Absinthe.Plug.GraphiQL,
      schema: BeSpiralWeb.Schema,
      socket: BeSpiralWeb.UserSocket,
      interface: :playground
    )
  end

  scope "/api", BeSpiralWeb do
    pipe_through(:api)

    get("/health_check", HealthCheckController, :index)

    post("/auth/sign_in", AuthController, :sign_in)
    post("/auth/sign_up", AuthController, :sign_up)

    post("/ipfs", IPFSController, :save)

    get("/chain/info", ChainController, :info)
    post("/chain/account", ChainController, :create_account)
  end
end
