use Mix.Config

config :bespiral, BeSpiralWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :bespiral, BeSpiral.Chat.ApiHttp,
  chat_base_url: "http://chat-server.bespiral.local:3002",
  chat_token: "kwt-XUNLrGm1cglSqUm4EjZavtsaZCypTXZY-xS4j83",
  chat_user_id: "Wc46q2sNqcE4ZhMKt",
  chat_user_role: "community-user"

config :bespiral, BeSpiral.Eos,
  bespiral_wallet: "default",
  bespiral_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  bespiral_account: "bespiral",
  mcc_contract: "bes.cmm",
  bespiral_cmm: "BES"

config :bespiral, BeSpiral.Repo,
  database: "bespiral_dev",
  username: "postgres",
  password: "",
  hostname: "localhost",
  port: "5432"

config :tesla, adapter: Tesla.Adapter.Hackney

config :bespiral, BeSpiral.Mailer, adapter: Bamboo.LocalAdapter

# Configure mockable modules
config :bespiral, :eosrpc_wallet, EOSRPC.Wallet
config :bespiral, :eosrpc_helper, EOSRPC.Helper
config :bespiral, :contract, BeSpiral.Eos
config :bespiral, :chat_api, BeSpiral.Chat.ApiHttp

config :logger, :console,
  # Do not include metadata nor timestamps in development logs
  format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 25

config :bespiral, :ipfs, conn: {}

config :eosrpc, EOSRPC.Wallet, url: "http://localhost:8888/v1/wallet"

config :eosrpc, EOSRPC.Chain, url: "http://eosio.bespiral.local/v1/chain"

# Configure Notifications Adapter 
config :bespiral, BeSpiral.Notifications, adapter: BeSpiral.Notifications.HttpAdapter

## configure push notifs
config :web_push_encryption, :vapid_details,
  subject: "https://bespiral.io",
  public_key:
    "BDzXEdCCYafisu3jmYxBGDboAfwfIHYzM9BbT2DmL8VzIqSWu5BnW6lC-xEoXExQUS81vwOSPF9w8kpcINWCvUM",
  private_key: "wQl-nXkfovd-pv1UNSKEAaarpyApZSrSVm1VW9UQIxE"
