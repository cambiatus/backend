use Mix.Config

config :cambiatus, CambiatusWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :cambiatus, Cambiatus.Eos,
  cambiatus_wallet: "default",
  cambiatus_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  cambiatus_account: "bespiral",
  mcc_contract: "bes.cmm",
  cambiatus_cmm: "BES"

config :cambiatus, Cambiatus.Repo,
  database: "cambiatus_dev",
  username: "postgres",
  password: "123123123",
  hostname: "localhost",
  port: "5432"

config :cambiatus, Cambiatus.Auth.InvitationId,
  salt: "y74669wSOtvUKv4niBSXfWbo/h90nV9Rpm9JfYCeD/cN/UbB3lPUxPtcmz/i+jpk"

config :tesla, adapter: Tesla.Adapter.Hackney

config :cambiatus, Cambiatus.Mailer, adapter: Bamboo.LocalAdapter

# Configure mockable modules
config :cambiatus, :eosrpc_wallet, EOSRPC.Wallet
config :cambiatus, :eosrpc_helper, EOSRPC.Helper
config :cambiatus, :contract, Cambiatus.Eos
config :cambiatus, :chat_api, Cambiatus.Chat.ApiHttp

config :logger, :console,
  # Do not include metadata nor timestamps in development logs
  format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 25

config :cambiatus, :ipfs, conn: {}

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  s3: [
    scheme: "https://",
    host: "cambiatus-uploads.s3.amazonaws.com",
    region: "us-east-1"
  ]

config :eosrpc, EOSRPC.Wallet, url: "http://localhost:8888/v1/wallet"

config :eosrpc, EOSRPC.Chain, url: "http://eosio.cambiatus.local/v1/chain"

# Configure Notifications Adapter
config :cambiatus, Cambiatus.Notifications, adapter: Cambiatus.Notifications.HttpAdapter

## configure push notifs
config :web_push_encryption, :vapid_details,
  subject: "https://cambiatus.io",
  public_key:
    "BDzXEdCCYafisu3jmYxBGDboAfwfIHYzM9BbT2DmL8VzIqSWu5BnW6lC-xEoXExQUS81vwOSPF9w8kpcINWCvUM",
  private_key: "wQl-nXkfovd-pv1UNSKEAaarpyApZSrSVm1VW9UQIxE"
