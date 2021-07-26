import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cambiatus, CambiatusWeb.Endpoint,
  http: [port: 4001],
  server: false

config :cambiatus, Cambiatus.Eos, url: "http://eosnode.test:8888"

config :cambiatus, :eosrpc_wallet, EOSRPC.WalletMock
config :cambiatus, :eosrpc_helper, EOSRPC.HelperMock
config :cambiatus, :eosrpc_chain, EOSRPC.ChainMock
config :cambiatus, :contract, Cambiatus.EosMock
config :cambiatus, :s3_client, Cambiatus.ExAwsMock

config :cambiatus, :graphql_secret, "pass"
config :cambiatus, :auth_salt, "test-salt"

# Print only warnings and errors during test
config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

config :cambiatus, Cambiatus.Mailer, adapter: Swoosh.Adapters.Test

config :cambiatus, Cambiatus.Auth.InvitationId,
  salt: "VG6ti1uWCJ9xg6076bslKiV3HChW8F5arCwksiIiLctDXpPL+mAgJUoZ5HRd/Hag"

config :cambiatus, Cambiatus.Repo,
  database: "cambiatus_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5432",
  pool: Ecto.Adapters.SQL.Sandbox

config :cambiatus, Cambiatus.Eos, cambiatus_account: "cambiatus"

config :cambiatus, Cambiatus.Notifications, adapter: Cambiatus.Notifications.TestAdapter
