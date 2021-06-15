import Config

config :cambiatus, Cambiatus.Eos,
  cambiatus_wallet: System.get_env("EOSIO_WALLET_NAME") || "default",
  cambiatus_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  cambiatus_account: System.get_env("BESPIRAL_ACCOUNT"),
  mcc_contract: System.get_env("BESPIRAL_CONTRACT"),
  cambiatus_cmm: System.get_env("BESPIRAL_AUTO_INVITE_CMM")

port = String.to_integer(System.get_env("PORT") || "8080")

config :cambiatus, CambiatusWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME"), port: port],
  root: ".",
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: CambiatusWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Cambiatus.PubSub

config :cambiatus, Cambiatus.Repo,
  database: System.get_env("DB_NAME"),
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: System.get_env("DB_HOST"),
  pool_size: 15

config :eosrpc, EOSRPC.Wallet, url: System.get_env("EOSIO_WALLET_URL")
config :eosrpc, EOSRPC.Chain, url: System.get_env("EOSIO_URL")
config :eosrpc, EOSRPC.Helper, symbol: System.get_env("EOSIO_SYMBOL") || "EOS"

config :cambiatus, :graphql_secret, System.get_env("GRAPHQL_SECRET")
config :cambiatus, :auth_salt, System.get_env("USER_SALT")

config :sentry,
  dsn: "https://cf10887ac4c346ebb26cbc3522578465@sentry.io/1467632",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production",
    url: System.get_env("HOSTNAME")
  },
  included_environments: [:prod]

config :web_push_encryption, :vapid_details,
  subject: System.get_env("HOSTNAME"),
  public_key: System.get_env("PUSH_PUBLIC_KEY"),
  private_key: System.get_env("PUSH_PRIVATE_KEY")
