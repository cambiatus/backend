use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bespiral, BeSpiralWeb.Endpoint,
  http: [port: 4001],
  server: false

config :bespiral, BeSpiral.Chat.ApiHttp,
  chat_base_url: "http://chat-server.bespiral.local:3002",
  chat_token: "token",
  chat_user_id: "user_id",
  chat_user_role: "role"

config :bespiral, BeSpiral.Eos, url: "http://eosnode.test:8888"

config :bespiral, :eosrpc_wallet, EOSRPC.WalletMock
config :bespiral, :eosrpc_helper, EOSRPC.HelperMock
config :bespiral, :contract, BeSpiral.EosMock
config :bespiral, :chat_api, BeSpiral.Chat.ApiMock

# Print only warnings and errors during test
config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

config :bespiral, BeSpiral.Mailer, adapter: Bamboo.TestAdapter

config :bespiral, BeSpiral.Repo,
  database: "bespiral_test",
  username: "postgres",
  password: "",
  hostname: "localhost",
  port: "5432",
  pool: Ecto.Adapters.SQL.Sandbox

config :bespiral, BeSpiral.Eos, bespiral_account: "bespiral"

config :bespiral, BeSpiral.Notifications, adapter: BeSpiral.Notifications.TestAdapter
