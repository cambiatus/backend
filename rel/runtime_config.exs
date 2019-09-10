use Mix.Config

config :bespiral, BeSpiral.Eos,
  bespiral_wallet: "default",
  bespiral_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  bespiral_account: System.get_env("BESPIRAL_ACCOUNT"),
  mcc_contract: System.get_env("BESPIRAL_CONTRACT"),
  bespiral_cmm: System.get_env("BESPIRAL_AUTO_INVITE_CMM")

port = String.to_integer(System.get_env("PORT") || "8080")

config :bespiral, BeSpiralWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME"), port: port],
  root: ".",
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: BeSpiralWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BeSpiral.PubSub, adapter: Phoenix.PubSub.PG2]

config :bespiral, BeSpiral.Chat.ApiHttp,
  chat_base_url: System.get_env("CHAT_BASE_URL"),
  chat_token: System.get_env("CHAT_TOKEN"),
  chat_user_id: System.get_env("CHAT_USER_ID"),
  chat_user_role: System.get_env("CHAT_USER_ROLE")

config :bespiral, BeSpiral.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: System.get_env("SENDGRID_KEY")

config :bespiral, :ipfs, conn: %{host: System.get_env("IPFS_URL"), port: 5001}

config :bespiral, BeSpiral.Repo,
  database: System.get_env("DB_NAME"),
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: System.get_env("DB_HOST"),
  pool_size: 15

config :eosrpc, EOSRPC.Wallet, url: System.get_env("EOSIO_WALLET_URL")

config :eosrpc, EOSRPC.Chain, url: System.get_env("EOSIO_URL")

config :bespiral, :chat_api, BeSpiral.Chat.ApiHttp

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
