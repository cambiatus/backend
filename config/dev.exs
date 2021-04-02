use Mix.Config

config :cambiatus, CambiatusWeb.Endpoint,
  http: [port: 4000, protocol_options: [idle_timeout: 30_000]],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../nodejs_auth", __DIR__)
    ]
  ]

config :cambiatus, Cambiatus.Eos,
  cambiatus_wallet: "default",
  cambiatus_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  cambiatus_account: "cambiatus",
  mcc_contract: "cambiatus.cm",
  cambiatus_cmm: "0,CMB"

config :cambiatus, Cambiatus.Repo,
  database: "cambiatus_dev",
  username: "postgres",
  password: "",
  hostname: "localhost",
  port: "5432"

config :cambiatus, Cambiatus.Auth.InvitationId, salt: "default-salt"

config :tesla, adapter: Tesla.Adapter.Hackney

config :cambiatus, Cambiatus.Mailer, adapter: Bamboo.LocalAdapter

# Configure mockable modules
config :cambiatus, :eosrpc_wallet, EOSRPC.Wallet
config :cambiatus, :eosrpc_helper, EOSRPC.Helper
config :cambiatus, :eosrpc_chain, EOSRPC.Chain
config :cambiatus, :contract, Cambiatus.Eos
config :cambiatus, :chat_api, Cambiatus.Chat.ApiHttp

config :cambiatus, :graphql_secret, "d8Ed.-qfhj7"
config :cambiatus, :auth_salt, "AVPLxwEAbi4Ff9Lw1IiBKZWYazWVafxm4PWs1WdXboaOt9galg6v8U4bPaSMjAtO"

config :logger, :console,
  # Do not include metadata nor timestamps in development logs
  format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 25

config :cambiatus, :ipfs, conn: {}

config :eosrpc, EOSRPC.Wallet, url: "http://127.0.0.1:8900/v1/wallet"
config :eosrpc, EOSRPC.Chain, url: "http://staging.cambiatus.io/v1/chain"
config :eosrpc, EOSRPC.Helper, symbol: "SYS"

# Configure Notifications Adapter
config :cambiatus, Cambiatus.Notifications, adapter: Cambiatus.Notifications.HttpAdapter

## configure push notifs
config :web_push_encryption, :vapid_details,
  subject: "https://cambiatus.io",
  public_key:
    "BDzXEdCCYafisu3jmYxBGDboAfwfIHYzM9BbT2DmL8VzIqSWu5BnW6lC-xEoXExQUS81vwOSPF9w8kpcINWCvUM",
  private_key: "wQl-nXkfovd-pv1UNSKEAaarpyApZSrSVm1VW9UQIxE"
